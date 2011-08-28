---
layout: dev_post
title: Making your Gem Warning Free
section: dev-blog
contents_class: medium-wide
published: false
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

The rake task included with RSpec provides all the configuration
options we need:

<script src="https://gist.github.com/1176143.js"> </script>

You'll notice I set `skip_bundler = true`; with bundler, I discovered
that the warnings were silenced.  I'm not sure why, but there's an
[open issue](https://github.com/carlhuda/bundler/issues/969) for it, so
hopefully it'll be fixed at some point. In the meantime, running the
specs without `bundle exec` works fine since I setup bundler in my
`spec_helper` file and only have one version of RSpec installed.

## Too many warnings

After making this change, when I run my specs, I'm greeted
with over 6500 lines of warnings like these:

<script src="https://gist.github.com/1176301.js"> </script>

...not exactly the most useful output. It's a bit overwhelming, and
beyond that, many of the warnings are coming from other libraries.

## My solution

What I really wanted is a list of unique warnings coming from VCR.
To that end, I came up with a way to filter and format the warnings:

<script src="https://gist.github.com/1176316.js"> </script>

In a nutshell, here's how it works:

* I redirect stderr into a temporary file, since ruby prints warnings to
  stderr.
* I pass `-r ./capture_warnings.rb` so that this file gets loaded
  first and ensures _all_ warnings get captured.
* In the `at_exit` hook, I reformat the output, printing only unique
  warnings that are traced back to files under the current directory
  (which is a good clue that VCR is responsible for them).
* Finally, I exit with a non-zero status if there are any warnings
  from VCR.  This will help me keep VCR warning-free by failing the
  build.

This made the output much more useful:

<script src="https://gist.github.com/1176335.js"> </script>

## My solution may not be your solution

This is working really well for me, but it definitely makes a couple
assumptions that may not be true of every project:

* It uses a very simple heuristic (`line.include?(current_dir)`) to
  figure out if VCR is responsible for the error.  Does ruby always
  include the current working directory in the output of every error?
  That seems to be the case so far but I have no idea if this is true.
* It assumes that all stderr output is from warnings.  This is true for
  my project but may not be true for yours.

I'm curious if others have come up with better or alternate solutions
to the problem of isolating the warnings output to just the ones your
code is responsible for.  Please let me know in the comments!

