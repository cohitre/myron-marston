---
layout: dev_post
title: How to Contribute to an Open Source Project
section: dev-blog
contents_class: medium-wide
---

_Note: I originally posted this on the
[SEOmoz Dev Blog](http://devblog.seomoz.org/2011/09/how-to-contribute-to-an-open-source-project/)
yesterday. I'm posting it here to keep all my writing in one place._

I contribute to open source on a fairly regular basis. Besides the fact
that I enjoy giving back to the community, it also helps make our applications
more maintainable: if I can get the bug fix or new feature I need back into an
open source library, rather than maintaining a local modification, it makes
future library upgrades far, far easier.

I commonly hear from other developers that they want to contribute to open
source projects but they are unsure how to get started.
[Kate](http://twitter.com/katemats) suggested I
distill my experiences of working on open source projects into a bit of a
"how to" guide for contributing to open source...so here goes :).

Virtually all of my open source experience has been with ruby projects on
github, so that'll be the focus of this blog post. I'm sure different code
communities have different conventions/standards around how to contribute
to open source, but these tips should prove useful regardless of what
community you are a part of.

## Look for opportunities to contribute

Most open source projects have some kind of bug/issue tracker, and you can
certainly look there to find ways to contribute. I don't recommend it,
though, especially if you're contributing to an open source project for
the first time. Instead, be on the lookout for pain points with the open
source libraries that you use. The next time you are dealing with a bug in
some library that you use, consider it an opportunity to give back to the
library, rather than working around it in your application. If there is a
feature that your application needs that is generically useful, consider
adding it directly to the library and contributing that back.

In general, the best open source contributions come from people who are
_solving their own problems_. If you're not the one who is having the problem,
you'll have difficulty adequately solving it.

No contribution is too small. I once spent over an hour trying to figure out
why [bundler](http://gembundler.com/) wasn't working on a project. I had
a simple Gemfile like this:

{% gist 1217354 Gemfile %}

The bundler output confounded me:

{% gist 1217354 Output.sh %}

I _knew_ [rubygems.org](http://rubygems.org) had RSpec in its source
index...and yet bundler was telling me otherwise. After troubleshooting
this for an hour, I realized I had specified the gem name using a ruby
symbol (i.e. `:rspec`) rather than a string (i.e. `"rspec"`). Sure enough,
when I changed it to a string, it worked.

My first contribution to bundler was [a simple patch](https://github.com/carlhuda/bundler/commit/5e6b09469afd16719cdc9a0856c6f0da0489f55f)
to provide a more useful
error message when gems are specified using symbols. As I said, no contribution
is too small.

## Setup your dev environment

Now that you've got a an idea of a patch you want to contribute to an open
source project, you need to get a proper development environment setup. Most
ruby projects have a "contributing" or "hacking" file that will help get you
started. For example, Ryan Tomayko's replicate
[lists instructions](https://github.com/rtomayko/replicate/blob/1.3/HACKING)
for getting started. For most ruby projects these days, you'll just need to
fork the project to your github account, `git clone` it, run `bundle install`
to get the dependencies intalled, and run a rake task to run the tests.

The tests are particularly important on an open source project. They are
the primary way the project maintainers communicate to you, the drive-by
contributor, how the pieces are supposed to work. With a well-tested project,
the tests give you confidence that your changes have not introduced a regression.

## Make your changes

Now that you have a development environment setup, it's time to make your
changes. In general, you should follow the conventions that are already
present in the project. It's not your job as a first-time contributor to
do a massive refactoring just because you prefer different conventions.
If in doubt about your changes, try to get in touch with the maintainers,
over IRC, a mailing list, the issue tracker, or over twitter.

When I'm working on fixing an issue in a project, and there are multiple
viable solutions, I'll often open a ticket describing the issue and possible
solutions, to solicit feedback before I make my changes. For example, before
making the change to bundler I described above, I
[asked for feedback](https://github.com/carlhuda/bundler/issues/434) from
the bundler team about how they wanted bundler to treat symbols.

## Ensure your changes are tested

Before submitting your patch, it's important that you include test coverage
for your change. As I said previously, the tests on an open source project
enable contributors to make changes with confidence they aren't introducing
regressions. If your patch does not include tests, future contributors may
inadvertently break your patch, and when they do so, it won't be their fault;
it'll be yours.

Many projects mention tests as a requirement for contributions, anyway, so
your patch will likely not be accepted unless it includes tests.

## Prepare your patch to be merged

It's a good idea to get your patch into an easily mergable form. You want to
make it as easy as possible for the project maintainers to merge your patch
in. With git, this usually means rebasing commits against the latest commit
on the master branch--that way you have already dealt with any merge conflicts,
and it's a simple, clean fast-forward for the project maintainers.

## Submit your patch

Finally, submit your patch to the project. On github, the preferred way these
days is through a pull request. The project maintainer may have further
suggestions before accepting your patch. Be sure to follow up on those.

If you have any additional tips on contributing to open source projects,
please let me know in the comments!

