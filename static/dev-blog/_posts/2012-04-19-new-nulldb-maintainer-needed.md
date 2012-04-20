---
layout: dev_post
title: New NullDB Maintainer Needed
section: dev-blog
contents_class: medium-wide
---

[NullDB](https://github.com/nulldb/nulldb) is a handy project that makes
it easy to write database-decoupled unit tests for your ActiveRecord
models. The project was originally started by [Avdi Grimm](http://avdi.org/);
two years ago, [I took over as
maintainer](http://devblog.avdi.org/2010/04/06/nulldb-has-a-new-maintainer/).

Since that time, I've focused my open source efforts on
[several](https://github.com/myronmarston/vcr)
[other](https://github.com/rspec/rspec-core/commits/master?author=myronmarston)
[projects](https://github.com/seancribbs/ripple/commits?author=myronmarston)
and I no longer have the time to maintain NullDB. I'm also not using
ActiveRecord much these days so I'm not using NullDB as regularly as I
used to. At this point there's a [backlog of issues and pull
requests](https://github.com/nulldb/nulldb/issues) that needs someone
with more time and interest than I to deal with.

I also have some ideas for some "next steps" I'd like to see for NullDB:

* It'd be great to get some CI builds going on [Travis](http://travis-ci.org/).
* NullDB should ideally be fully de-coupled from Rails, so that it can
  easily be used in non-Rails ActiveRecord projects. A Rails 3 RailTie
  can be used for deeper NullDB/Rails integration without coupling them.
* RSpec 2 provides a great API for testing libraries to easily integrate
  with examples and example groups using metadata. It'd be great if
  NullDB took advantage of this (e.g. so that all specs except those
  tagged with `:realdb` used the NullDB adapter by default).
* NullDB still "officially" supports Ruby 1.8.6 and Rails 2.x. I think
  it's time to drop support for those.

If you're interested in helping maintain NullDB, let me know, via a comment
below, a tweet or an email. If you're interested in helping out but
don't think you have the time to take over as the main maintainer,
that's fine--it'd be great to get multiple people who can help out!
