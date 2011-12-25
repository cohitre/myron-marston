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

{% codeblock Rakefile lang:ruby %}
RSpec::Core::RakeTask.new(:spec) do |t|
  t.ruby_opts = "-w"
  t.skip_bundler = true
end
{% endcodeblock %}

You'll notice I set `skip_bundler = true`; when the specs were run with `bundle exec`, I discovered
that the warnings were silenced.  I'm not sure why, but there's an
[open issue](https://github.com/carlhuda/bundler/issues/969) for it, so
hopefully it'll be fixed at some point. In the meantime, running the
specs without `bundle exec` works fine since I setup bundler in my
`spec_helper` file and only have one version of RSpec installed.

## Too many warnings

After making this change, when I run my specs, I'm greeted
with over 6500 lines of warnings like these:

{% codeblock warnings.txt lang:sh %}
/Users/myron/code/vcr/lib/vcr.rb:146: warning: instance variable @turned_off not initialized
/Users/myron/code/vcr/spec/support/sinatra_app.rb:36: warning: instance variable @_boot_failed not initialized
/Users/myron/.rvm/gems/ruby-1.9.2-p290@vcr/gems/excon-0.6.5/lib/excon/connection.rb:46: warning: instance variable @proxy not initialized
/Users/myron/.rvm/gems/ruby-1.9.2-p290@vcr/gems/excon-0.6.5/lib/excon/connection.rb:46: warning: instance variable @proxy not initialized
/Users/myron/.rvm/gems/ruby-1.9.2-p290@vcr/gems/faraday-0.7.4/lib/faraday/connection.rb:142: warning: instance variable @proxy not initialized
/Users/myron/.rvm/gems/ruby-1.9.2-p290@vcr/gems/faraday-0.7.4/lib/faraday/connection.rb:142: warning: instance variable @proxy not initialized
/Users/myron/code/vcr/lib/vcr.rb:146: warning: instance variable @turned_off not initialized
/Users/myron/.rvm/gems/ruby-1.9.2-p290@vcr/gems/typhoeus-0.2.4/lib/typhoeus/hydra.rb:124: warning: instance variable @cache_getter not initialized
{% endcodeblock %}

...not exactly the most useful output. It's a bit overwhelming, and
beyond that, many of the warnings are coming from other libraries.

## My solution

What I really wanted is a list of unique warnings coming from VCR.
To that end, I came up with a way to filter and format the warnings:

{% codeblock capture_warnings.rb %}
require 'tempfile'
stderr_file = Tempfile.new("vcr.stderr")
$stderr.reopen(stderr_file.path)
current_dir = Dir.pwd

at_exit do
  stderr_file.rewind
  lines = stderr_file.read.split("\n").uniq
  stderr_file.close!

  vcr_warnings, other_warnings = lines.partition { |line| line.include?(current_dir) }

  if vcr_warnings.any?
    puts
    puts "-" * 30 + " VCR Warnings: " + "-" * 30
    puts
    puts vcr_warnings.join("\n")
    puts
    puts "-" * 75
    puts
  end

  if other_warnings.any?
    File.open('tmp/warnings.txt', 'w') { |f| f.write(other_warnings.join("\n")) }
    puts
    puts "Non-VCR warnings written to tmp/warnings.txt"
    puts
  end

  # fail the build...
  exit(1) if vcr_warnings.any?
end
{% endcodeblock %}

{% codeblock Rakefile %}
RSpec::Core::RakeTask.new(:spec) do |t|
  t.ruby_opts = "-w -r./capture_warnings"
  t.skip_bundler = true
end
{% endcodeblock %}

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

{% codeblock warnings_output.txt lang:diff %}
------------------------------ VCR Warnings: ------------------------------

/Users/myron/code/vcr/spec/vcr/cassette/reader_spec.rb:24: warning: useless use of == in void context
/Users/myron/code/vcr/spec/support/shared_example_groups/ignore_localhost_deprecation.rb:15: warning: `*' interpreted as argument prefix
/Users/myron/code/vcr/spec/support/shared_example_groups/normalizers.rb:1: warning: loading in progress, circular require considered harmful - /Users/myron/code/vcr/spec/spec_helper.rb
	from /Users/myron/code/vcr/spec/vcr/cassette/reader_spec.rb:1:in `<top (required)>'
	from /Users/myron/code/vcr/spec/vcr/cassette/reader_spec.rb:1:in `require'
	from /Users/myron/code/vcr/spec/spec_helper.rb:14:in `<top (required)>'
	from /Users/myron/code/vcr/spec/spec_helper.rb:14:in `each'
	from /Users/myron/code/vcr/spec/spec_helper.rb:14:in `block in <top (required)>'
	from /Users/myron/code/vcr/spec/spec_helper.rb:14:in `require'
	from /Users/myron/code/vcr/spec/support/shared_example_groups/normalizers.rb:1:in `<top (required)>'
	from /Users/myron/code/vcr/spec/support/shared_example_groups/normalizers.rb:1:in `require'
/Users/myron/code/vcr/lib/vcr/config.rb:47: warning: `*' interpreted as argument prefix
/Users/myron/code/vcr/lib/vcr.rb:146: warning: instance variable @turned_off not initialized
/Users/myron/code/vcr/lib/vcr/http_stubbing_adapters/fakeweb.rb:70: warning: instance variable @http_connections_allowed not initialized

---------------------------------------------------------------------------


Non-VCR warnings written to tmp/warnings.txt
{% endcodeblock %}

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
