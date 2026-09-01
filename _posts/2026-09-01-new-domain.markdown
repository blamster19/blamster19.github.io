---
layout: post
title:  Migration to a new domain and hosting
date:   2026-09-01 18:16:10 +0200
categories:
tags: linux programming web
excerpt: I'm on a journey to an online presence on my own terms. It is time for a permanent domain and new hosting.
---

# Important notice

For regular readers and feed subscribers (if there are any), the new address is <https://blamster19.net>. The GitHub link <https://blamster19.github.io> will not be updated in the future.

# What changed

I migrated my site from GitHub Pages to [Codeberg Pages](https://codeberg.page/). This is a part of my larger move towards the digital independence from the Big Tech entities. The move was relatively painless, I just had to:

* create a new branch named `pages` holding a subtree located in the directory with the HTML files - Codeberg expects the HTML to reside in the root directory
* create a file `.domains` that lists the domains from which I want my site to be reachable (not sure if it's needed now)
* push to a Codeberg repository named `pages`
* create a webhook in the repository with the target URL being my custom domain and branch filter set to `pages`
* create the DNS records in my registrar: `ALIAS codeberg.page.` and `TXT https://codeberg.org/blamster19/pages.git`, the second one with host `_git-pages-repository.www.blamster19.net`
* pushing changes is done with `$ git subtree push --prefix pages codeberg gh-pages` where `pages` is the branch with HTML files, `codeberg` is the Codeberg remote and `gh-pages` is the repository containing all project files

I got a domain from <https://porkbun.com>. Not much to say here, So far it looks good.

Figuring those things out is very fun and rewarding. I definitely advise to try and set up a website [from scratch](/2026/08/20/static-blog-bash.html) and hook it up to your own domain. I even had my own infamous DNS problems along the way!
