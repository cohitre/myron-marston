---
layout: dev_post
title: Making your Gem Warning Free
section: dev-blog
contents_class: wide
---

There's been an [on-going](http://avdi.org/devblog/2011/06/23/how-ruby-helps-you-fix-your-broken-code/)
[discussion](http://mislav.uniqpath.com/2011/06/ruby-verbose-mode/) in the ruby community recently about
warnings. I've never used ruby's `-w` much, but I'm always in favor of
more automated tools that can help improve your code. Furthermore, as a
gem author, I strive to make my gems play nice with other ruby tools.
Some rubyists will never run their code with `-w`, but for those who
do, I don't want my gems to generate warnings for them.

The primary gem I work on is [VCR](http://relishapp.com/myronmarston/vcr), and I decided
that it was time to make it warning free.

## Initial configuration

<script src="https://gist.github.com/1161260.js"> </script>

