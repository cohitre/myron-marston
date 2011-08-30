---
layout: dev_post
title: Making your Gem Warning Free
section: dev-blog
contents_class: medium-wide
---

There's been an [on-going](http://avdi.org/devblog/2011/06/23/how-ruby-helps-you-fix-your-broken-code/)
[discussion](http://mislav.uniqpath.com/2011/06/ruby-verbose-mode/) in the ruby community recently about
warnings. I've never used ruby's `-w` option much, but I'm always in favor of
more automated tools that can help improve my code. Furthermore, as a
gem author, I strive to make my gems play nice with other ruby tools.
Some rubyists will never run their code with `-w`, but for those who
do, I don't want my gems to generate warnings for them.

The primary gem I work on is [VCR](http://relishapp.com/myronmarston/vcr), and I decided
that it was time to make it warning free.

## Initial configuration

The rake task included with RSpec provides all the configuration
options we need:

{% gist 1176143 Rakefile %}

You'll notice I set `skip_bundler = true`; when the specs were run with `bundle exec`, I discovered
that the warnings were silenced.  I'm not sure why, but there's an
[open issue](https://github.com/carlhuda/bundler/issues/969) for it, so
hopefully it'll be fixed at some point. In the meantime, running the
specs without `bundle exec` works fine since I setup bundler in my
`spec_helper` file and only have one version of RSpec installed.

## Too many warnings

After making this change, when I run my specs, I'm greeted
with over 6500 lines of warnings like these:

{% gist 1176301 warnings.txt %}

...not exactly the most useful output. It's a bit overwhelming, and
beyond that, many of the warnings are coming from other libraries.

## My solution

What I really wanted is a list of unique warnings coming from VCR.
To that end, I came up with a way to filter and format the warnings:

{% gist 1176316 capture_warnings.rb %}
{% gist 1176316 Rakefile %}

In a nutshell, here's how it works:

* I redirect stderr into a temporary file, since ruby prints warnings to
  stderr.
* I pass ruby a `-r ./capture_warnings.rb` option so that this file gets loaded
  first and ensures _all_ warnings get captured.
* In the `at_exit` hook, I reformat the output, printing only unique
  warnings that originate from files under the current directory
  (which is a good clue that VCR is responsible for them).
* Finally, I exit with a non-zero status if there are any warnings
  from VCR.  This will help me keep VCR warning-free in the future
  by failing the build and forcing me to remove the warnings.

This made the output much more useful:

{% gist 1176335 warnings_output.txt %}

## My solution may not be your solution

This is working really well for me, and I just released VCR 1.11.2
yesterday with all warnings fixed. That said, my solution definitely
makes a couple assumptions that may not be true of every project:

* It uses a very simple heuristic (`line.include?(current_dir)`) to
  figure out if VCR is responsible for the warning.  Does ruby always
  include the current working directory in the output of every warning
  that originates from code in your current working directory?
  That seems to be the case so far but I have no idea if this is true.
  [^foot]
* It assumes that all stderr output is from warnings.  This is true for
  my project but may not be true for yours.

I'm curious if others have come up with better or alternate solutions
to the problem of isolating the warnings output to just the ones your
code is responsible for.  Please let me know in the comments!

[^foot]: Actually, on JRuby, I had the opposite problem: Excon
[uses an instance variable before it has been
defined](https://github.com/geemus/excon/blob/v0.6.5/lib/excon/connection.rb#L46),
but JRuby [reported the
warning](http://travis-ci.org/#!/myronmarston/vcr/builds/106602)
as originating from one of VCR's files.  Weird.
