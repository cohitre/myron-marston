---
layout: dev_post
title: In Defense of 100% Test Coverage
section: dev-blog
contents_class: medium-wide
---

I'd like to talk a bit about something that seems to be almost universally
unpopular these days: 100% test coverage.  A few people like
[Uncle Bob Martin](https://twitter.com/#!/unclebobmartin/statuses/190125475543261184)
have said positive things about it, but the more popular sentiment is
closer to what [DHH](http://37signals.com/svn/posts/3159-testing-like-the-tsa)
says about it: don't bother aiming for it.

## TL;DR

You should not make 100% test coverage the focus of your testing
practice, but when applied carefully, I've found it useful on
some kinds of projects, particularly as an automated "dead code" finder.

## Why 100% Test Coverage Can be a Waste

Let's address some common criticisms to start with:

* When dev managers mandate 100% test coverage on their developers,
  it encourages the devs to write terrible tests that are written
  just to meet the goal.
* In a high-level language like Ruby, you commonly have one-liner
  class-level macros that are "covered" simply by loading the
  class in the test environment. For example, a `validates_presence_of :name`
  declaration in your ActiveRecord model will be reported as covered by your
  code coverage tool as soon as the model is loaded in your test
  environment...but yet, there is very real behavior here that isn't
  being tested at all. Thus, the code coverage number can be deceiving.
* Having 100% test coverage on a project gives a false sense of
  confidence. A project can be littered with bugs and yet still
  have 100% test coverage.
* There is a cost associated with your test suite. The longer it takes
  to run, the longer your red-green-refactor cycle takes. Excess
  tests that were written to satisfy a code coverage number may be
  brittle and drive up the cost of change on a project (as you have to
  fix numerous tests for each change you make).

I absolutely agree with every single one of these criticisms.
Test coverage should never be the goal, and making it the focus
of your testing practice can lead to very poor tests.

That said, even though it should never be the _focus_ of how write
your tests, I have 100% test coverage as reported by
[SimpleCov](https://github.com/colszowka/simplecov)
on multiple projects, and on these projects, my CI builds will
fail if the test coverage drops below 100%. I find 100% test
coverage to be useful and worthwhile on certain kinds of projects.
I'd like to explain why I find it useful and how I generally
approach test coverage.

## 100% Test Coverage as an Automated "Dead Code" Finder

A common problem on older projects is crufty code: code that may not
be used anymore, but no one's really sure, so the code gets left
in the code base, "just in case". Over time, this build up of
cruft can incur significant cost in a project. Wouldn't it be
great if there was an automated tool that helped identify dead
code that can safely be removed?

It turns out there is. Your code coverage tool, paired with making
it a part of your continuous integration builds, can serve this purpose.
It's a key benefit my projects have gotten out of maintaining 100%
test coverage, and, surprisingly, I've never heard any one mention it
before.

The high level of test coverage I keep makes it possible for me to
refactor my code ruthlessly. I often wind up with helper classes
or methods that are not unit tested directly; they are not part of
the public interface of the project, and serve to support some other
method or class that is part of the public interface. Later on,
when I refactor yet again, these helper methods or classes may no
longer be used, and, if they still remain in the code base, the
build will fail and tell me. This has helped me many times.

## What 100% Test Coverage does (and does not) Guarantee

As I've already mentioned, I refactor my code ruthlessly, and it's a
huge benefit I get out of practicing TDD. Maintaining a high level of
test coverage increases my confidence in the safety of my refactorings.

It's true that 100% test coverage can give a false sense of the
"robustness" of a project, and I know that having 100% test coverage
guarantees me nothing. However, having less than 100% test coverage
does guarantee something: it guarantees that a project's test
suite will be unable to detect when a refactoring breaks the
uncovered code. Every bit of a uncovered code is a potential source
of undetectable breakage, and I like to minimize these by keeping
my test coverage up.

## How I Use Test Coverage

The most important thing is to use your brain--don't aim
for 100% test coverage because I've found it useful, and don't
heap scorn on the practice because of what others say. Still,
here are some guidelines that I've found useful:

* Not every project needs or warrants 100% test coverage. I've never
  maintained 100% test coverage in a rails app and probably never will.
  In general, the more UI a project has, the less need for high test
  coverage number. Most of my projects these days are backend
  services (which often expose an HTTP API) or gems we use internally,
  and it makes much more sense to maintain test coverage on
  these sorts of projects.
* If you manage developers, don't ever mandate a test coverage
  threshold. It's a bad idea for a team to focus their testing practice
  on a test coverage threshold. A team can (and should) come to a
  consensus about what test coverage threshold they want (if any)
  for themselves.
* If you want to use your code coverage tool as an automated "dead
  code" finder, it's helpful to start the project at 100% test coverage.
  Using a lower threshold makes it harder to detect dead code since
  the coverage number will vary as you write and refactor code.
* In my minute-by-minute TDD cycle, I don't think about test
  coverage _at all_, and I usually run my tests without SimpleCov
  being loaded. I have a rake task that runs the tests with SimpleCov
  loaded and verifies the coverage threshold. I use this right before
  pushing commits and as part of my CI build. The majority of the time,
  the tests I've naturally written have 100% coverage.
* Occasionally when there are holes in the coverage, it doesn't really
  make sense to add tests for it. Generally, I'll extract this code into
  another file and add a SimpleCov
  [filter](http://rubydoc.info/gems/simplecov/0.6.3/frames) so that it
  ignores the file and does not count it when calculating the coverage
  percent. This allows me to continue using SimpleCov as a dead code
  finder, without having to add silly tests that would exist only to
  satisfy the coverage tool.

