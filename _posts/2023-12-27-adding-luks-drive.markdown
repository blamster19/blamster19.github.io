---
layout: post
title:  Adding new drive to LUKS encrypted setup
date:   2023-12-27 23:59:30 +0200
categories:
tags: linux LUKS encryption partitions
excerpt: A not-so-obvious task of extending available space.
---

After two years of flawless usage of my ThinkPad E15 gen-2 I ran out of space on its default 256 GB SSD drive. For christmas I bought myself a new shiny [1 TB M.2 SSD](https://www.kingston.com/en/ssd/kc3000-nvme-m2-solid-state-drive) and appended it to my LVM setup. The setup was:
```bash
$ lsblk
NAME                     MAJ:MIN RM   SIZE RO TYPE  MOUNTPOINTS
nvme1n1                  259:0    0 953,9G  0 disk
nvme0n1                  259:1    0 238,5G  0 disk
├─nvme0n1p1              259:2    0   476M  0 part  /boot/efi
├─nvme0n1p2              259:3    0   954M  0 part  /boot
└─nvme0n1p3              259:4    0 237,1G  0 part
  └─nvme0n1p3_crypt      254:0    0 237,1G  0 crypt
    ├─vg--1ThinkPad-swap 254:1    0  27,9G  0 lvm   [SWAP]
    ├─vg--1ThinkPad-root 254:2    0  37,3G  0 lvm   /
    ├─vg--1ThinkPad-var  254:3    0    14G  0 lvm   /var
    ├─vg--1ThinkPad-tmp  254:4    0   1,9G  0 lvm   /tmp
    └─vg--1ThinkPad-home 254:5    0   156G  0 lvm   /home
```

I followed [this answer on Stack Exchange](https://unix.stackexchange.com/questions/618877/how-can-i-add-a-new-physical-volume-to-extend-an-existing-luks-encrypted-lvm-vo) tailoring it to my needs. After booting up with SSD in place I opened _GNOME Disks_ utility and checked the name and path to my new asset, in my case, `/dev/nvme1n1` (visible in window titlebar upon selecting the drive). I also ran benchmark to find that the average read rate is 1,8 GB/s and write rate 1,0 GB/s. I also wanted to be able to unlock both drives at once, which I managed to do by using [this](https://unix.stackexchange.com/questions/392284/using-a-single-passphrase-to-unlock-multiple-encrypted-disks-at-boot) tip.

I proceeded to execute the following commands based on Stack Exchange:
```bash
$ sudo cryptsetup luksFormat /dev/nvme1
$ sudo cryptsetup luksOpen /dev/nvme1
$ sudo -e /etc/crypttab
```
in it, I had one line about my old drive. I copied it and changed the name and UUID to match the new drive data like so:
```
nvme0n1p3_crypt UUID=85c7f21e-b237-4ba6-84c3-11e737968a67 none luks,initramfs,keyscript=decrypt_keyctl
nvme1n1_crypt UUID=81e37db2-a64e-47d6-ace0-b037416712c6 none luks,initramfs,keyscript=decrypt_keyctl
```
I took the UUID from the output of `$ sudo blkid`. The `initramfs` flag is very important; without it my new partition did not mount and the OS dropped to _initramfs_ on every boot. I had to manually `cryptsetup luksOpen` it and exit to load into GUI. Solution was inspired by [this problem](https://unix.stackexchange.com/questions/643344/linux-mint-20-with-luks-and-lvm-hangs-on-boot-after-upgrade). Then I did:
```bash
$ sudo update-initramfs -c -k all
$ sudo cryptsetup luksOpen /dev/nvme1n1 nvme1n1_crypt
```
and entered the new passphrase. Moving on:
```bash
$ sudo pvcreate /dev/mapper/nvme1n1_crypt
$ sudo vgs
```
This showed me that my volume group is `vg-1ThinkPad`. Next I executed:
```bash
$ sudo vgextend vg-1ThinkPad /dev/mapper/nvme1n1_crypt
```
I wanted to create aditional partition for data with very original name `data` (I will leave moving `/home` fot another time), so I created and formatted it to ext4:
```bash
$ sudo lvcreate -l 100%FREE -n data vg-1ThinkPad /dev/mapper/nvme1n1_crypt
$ sudo mkfs.ext4 /dev/vg-1ThinkPad/data
```
Finally I chose a mount point:
```bash
$ sudo mkdir /mnt/data
$ sudo mount /dev/vg-1ThinkPad/data /mnt/data/
```
and added appropriate line to `/etc/fstab`
```
/dev/mapper/vg--1ThinkPad-data /mnt/data            ext4    defaults   0    2
```
I installed `keyutils` from _apt_ and updated `initramfs` again just in case and also run `update-grub`. And voilà. You have a fresh partition ready to be clogged with data.

