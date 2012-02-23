---
layout: dev_post
title: Testing Unicorn Configuration Hooks
section: dev-blog
contents_class: medium-wide
published: false
---

This past week I accidentally took down an app I'm responsible for when
I deployed what I thought was solid, tested code.  Luckily, I quickly
found the source of the problem, fixed it and deployed, getting the app
back up within 5 minutes.

The experience showed me that I had an important hole in my test coverage.
