---
layout: post
title:  Setting up Nextcloud on Raspberry Pi 3 Model B
date:   2025-03-16 02:36:00 +0100
categories:
tags: electronics Raspberry Pi Nextcloud
excerpt: Hosting your own data storage and online services is a fun pastime project if you do not mind occasional data loss… just kidding.
---

# Prelude

On my way to true digital independence I decided to set up my own cloud service. I tried to find the most hassle-free way to do it, hence I went with a Nextcloud instance on a Raspberry Pi 3 Model B I had lying around. It was not a totally trivial task since everything had to be set up in a quite restrictive confines of Eduroam network and without an external display. I managed to get a working service, but frequent connection issues I am having due to reverse proxy and network setup prevent me from fully enjoying the functionality of my server. Still, the project was worth the time it took.

# System setup

For my system I have decided to go with plain [Raspberry Pi OS Lite 64 bit](https://www.raspberrypi.com/software/operating-systems/). I used the *Raspberry Pi Imager* app from Flathub. After flashing and booting up my Pi, the machine connected to my hotspot.
Te first thing I did was to install [Raspberry Pi Connect](https://www.raspberrypi.com/documentation/services/connect.html) to never lose the access to my Raspberry Pi in case I have problems connecting through SSH in my dorm's WI-Fi. I issued

```bash
$ sudo apt install rpi-connect-lite
$ loginctl enable-linger
$ rpi-connect on
$ rpi-connect signin
```

and signed in. I rebooted the Pi to see if I set up everything correctly. Establishing connection through RPi Connect takes a while, but works.  
Next I set up the network connection. Eduroam which is a bit different from your usual Wi-Fi connection. I ran

```bash
$ sudo nmtui
```

and added a connection with such parameters:

```bash
           Profile name eduroam_________________________________
                 Device wlan0 (B8:27:EB:AA:7E:5A)_______________
                                                                
+ WI-FI                                                         
|                  SSID eduroam_________________________________
|                  Mode <Client>                                
|                                                               
|              Security <WPA & WPA2 Enterprise>                 
|        Authentication <PEAP>                                  
|    Anonymous identity PROVIDED BY UNI_________________________
|                Domain ________________________________________
|               CA cert ________________________________________
|      CA cert password ________________________________________
|                       [ ] Show password                       
|          PEAP version <Automatic>                             
|  Inner authentication <MSCHAPv2>                              
|              Username PROVIDED BY UNI_________________________
|              Password PROVIDED BY UNI_________________________
|                       [ ] Show password                       
|                       <Store password for all users>          
|                                                               
|                 BSSID ________________________________________
|    Cloned MAC address ________________________________________
|                   MTU __________ (default)                    
\                                                               
                                                                
- IPv4 CONFIGURATION    <Automatic>                             
- IPv6 CONFIGURATION    <Automatic>                             
                                                                
[X] Automatically connect                                       
[X] Available to all users                                      
```

I do not need a certificate to connect but I know some schools require it, so refer to your network staff's manual. For me this did the trick, although I had to wait a couple of minutes for my RPi to show up in Connect.  
I wanted to store my data on external USB SSD drive, which is already formatted to ext4. I set up automatic mount:

```bash
$ sudo mkdir /mnt/ssd-data-mount
$ sudo mount -t ext4 /dev/sda1 /mnt/ssd-data-mount/
$ sudo systemctl daemon-reload
$ sudo blkid
```

I took note of the `UUID=` value, made a backup of `/etc/fstab` and edited it by appending

```bash
UUID=d49402b9-7e8c-4cfc-aba5-253585a8911c /mnt/ssd-data-mount ext4 defaults,auto,users,rw,nofail 0 0
```

where the value of *UUID* is the one I copied from previous command. In the end I created a directory for my data:

```bash
$ mkdir /mnt/ssd-data-mount/nextcloud-data
$ sudo chmod 750 -R /mnt/ssd-data-mount/nextcloud-data
$ sudo chown www-data:www-data /mnt/ssd-data-mount/nextcloud-data -R
```

# Webserver

Now I could set up the proper functionality of my cloud server.  
First I installed and configured *UFW*

```bash
$ sudo apt install ufw
$ sudo ufw allow 80
$ sudo ufw allow 443
$ sudo ufw allow 3478
$ sudo ufw enable
```

Since I cannot port forward in the Eduroam network I settled for [Loophole](https://loophole.cloud/) to tunnel the traffic to my Pi. I downloaded the CLI Linux arm64 executable from their website. Next I created a `~/server-config` directory where I store all the behind-the-scenes configuration scripts. I `unzip`ped the package into my new directory, `cd`ed into it and ran

```bash
$ ./loophole account login
```

and logged in in the browser. Now to run the forwarding just run

```bash
$ ./loophole http 443 --hostname HOSTNAME
```

where `HOSTNAME` is some name you will remember.  
I created `startup-script.sh` populated with

```bash
#!/bin/bash

cd ~/server-config
./loophole http 443 --hostname HOSTNAME &
./loophole http 80 --hostname HOSTNAME &
```

and made it executable and immediately added te service to *systemd* by creating a file `/etc/systemd/system/server-startup.service`:

```
[Unit]
Description=Startup script activation
After=multi-user.target
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=pi
ExecStart=/home/pi/server-config/startup-script.sh

[Install]
WantedBy=multi-user.target
```

and finally

```bash
$ sudo systemctl daemon-reload
$ sudo systemctl enable server-startup.service
```

I also set `/etc/hostname` to my domain from *Loophole*, e.g. `HOSTNAME.loophole.site`.  
I went with bare metal *Nextcloud* install instead of Docker one. I installed the prerequisites

```bash
$ sudo apt install apache2 mariadb-server libapache2-mod-php 
$ sudo apt install php-gd php-json php-mysql php-curl php-mbstring php-intl php-imagick php-xml php-zip php-fpm
$ sudo service apache2 restart
```

and downloaded Nextcloud

```bash
$ cd /var/www/html
$ sudo wget https://download.nextcloud.com/server/releases/latest.zip
$ sudo unzip latest.zip
$ sudo chmod 750 nextcloud -R
$ sudo chown www-data:www-data nextcloud -R
```

I setup of MySQL:

```bash
$ sudo mysql
```

and in the interactive console I issued:

```
CREATE USER 'nextcloud' IDENTIFIED BY 'password';
CREATE DATABASE nextcloud;
GRANT ALL PRIVILEGES ON nextcloud.* TO 'nextcloud'@localhost IDENTIFIED BY 'password';
FLUSH PRIVILEGES;
quit
```

Next I set the contents of `/etc/apache2/sites-available/nextcloud.conf` to

```
Alias /nextcloud "/var/www/html/nextcloud/"

<Directory /var/www/html/nextcloud/>
  Require all granted
  AllowOverride All
  Options FollowSymLinks MultiViews

  <IfModule mod_dav.c>
    Dav off
  </IfModule>

</Directory>
```

then

```bash
$ sudo a2enmod headers
$ sudo systemctl reload apache2
```
I also edited `/var/www/html/nextcloud/config/config.php` so that `trusted_domains` **contains my domain and not the IP addresses** and also changed and added the following fields a few lines down:

```
'overwrite.cli.url' => 'example.com',
'overwritehost' => 'example.com',
```
  
where `example.com` is your domain obtained from Loophole (without `http://` part). This is important because otherwise the site will redirect to `127.0.0.1` everytime you want to access it through your domain. Leaving the IP of Raspberry Pi in my local network produced error 502 when accessed from the outside, even it I could access it through my domain inside of the network.  
Now I could access my Nextcloud page and start tweaking and uploading my data.

# Result

The Nextcloud server on Raspberry Pi 3 works, but is far from perfect. The web interface is not snappy and file uploads are slow, but for a device eight years of age and with 1 GB of RAM it fares pretty well. Unfortunately my Eduroam setup frequently breaks for seemingly no reason, website either throws error 502 or is unreachable. This is remedied either by reboot (sometimes a few times) or by leaving it be in hope it works again (sometimes it does!).  
Before writing this post I tested similar setup (Loophole forwarding included) in my private network at home and to my surprise it was quite stable. Unfortunately, when I moved it over to the dorm my SSD died, probably because of a faulty power outlet. Before that I managed to run it for about two weeks during which I set up auto sync of photos and GPS tracking data from my phone and backup of files from my laptop. Overall file syncing worked like a charm. The same cannot be said about browsing said data in web UI. Loading photos took ages and browsing treks in [GpxPod](https://apps.nextcloud.com/apps/gpxpod) froze the server to the point of needing reboot. [Preview Generator](https://apps.nextcloud.com/apps/previewgenerator) helped, but was not enough to get smooth experience.

# Conclusion

Setting up a Nextcloud instance on Raspberry Pi is a good introduction to server management and selfhosting. I believe Raspberry Pi 4 or 5 would be more appropriate choice for this task than 3, but for those ready to forgo most of the bells and whistles of Nextcloud it can be a very usable option as well.