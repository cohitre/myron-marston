---
layout: dev_post
title: Custom Request Matchers in VCR 2.0
section: dev-blog
contents_class: medium-wide
---

Over the last six weeks, I've been working extensively on VCR 2.0.
I've completely rewritten most of the internals and have finally
been able to add a feature people have wanted in VCR for over a
year: custom request matchers.

I just released VCR 2.0 beta 1 a few days ago, so I figured it's
time to blog a bit about what the feature is, why it's useful,
and why it took me so long to add it to VCR.

## The problem

VCR, at its core, is a very simple idea: you run your tests for
the first time, and VCR records the HTTP requests and responses.
Later, when you run them again, it will use the recorded responses
rather than allowing real ones, which has many benefits (speed,
test determinism and test accuracy being the main ones).

It's important for VCR to replay the _right_ response, and it
can't simply rely on the order of the recorded HTTP interactions.
You might be using a single cassette for multiple tests, and those
tests may not always run in the same order. Or you may change your
implementation code so that it makes the HTTP requests in a different
order. VCR needs a way to match a recorded HTTP interaction to
a new one.

Since VCR 1.1.0 (now over a year ago), VCR has allowed users to
customize how it matches a previously recorded HTTP interaction to
a new request, by using the [`:match_requests_on` cassette
option](https://www.relishapp.com/myronmarston/vcr/v/1-11-3/docs/cassettes/request-matching).
By default, it matches on `:uri` and `:method`, which works great
for most REST-ish APIs.

This gave VCR some nice flexibility, but it never really worked
well for the most common case where the `:uri`/`:method` matching
didn't work: APIs that have non-deterministic URIs. Each time your
tests run, the URI is different, and VCR would not match the new request the old
one, causing it to either re-record the HTTP interaction, or raise
a "real connections are not allowed" error, depending on your
configuration.

The common example is an API that requires clients to sign requests
by putting a token (typically generated by hashing several things,
including a timestamp) as a query parameter in the URI. Amazon's
APIs do this all over the place. It's a really bad idea to design
your APIs this way [^foot], but it's a reality of the web and VCR
needs to work well for users who are using these APIs.

## How VCR 1.x worked

I've wanted to make VCR work well for these sorts of APIs for a long
time, but the way VCR 1.x worked prevented a good solution. In VCR 1.x,
it uses declaritive APIs provided by FakeWeb, WebMock and Typhoeus.
When you insert a cassette, VCR makes calls to these libraries that
are a bit like this:

{% gist 1272818 vcr_stubs.rb %}

These libraries all allow you to register a stub using a regex rather
than a full URI, and this is in fact what VCR 1.x did to support
`:match_requests_on => [:host, :path]`. This works OK, but doesn't
provide an easy way to solve the problem of URIs with non-deterministic
query parameters. Building a regex that correctly matches all of a URI
except a particular query parameter is not easy, and it would have been
even more difficult to put code that does this generically in VCR so
that users could easily match on a URI while ignoring particular query
parameters.

## The big rewrite

I realized about a year ago that if I was going to solve this problem
in VCR, I needed to change the way VCR interacts with FakeWeb, WebMock,
and Typhoeus: rather than using their declaritive stub registration
APIs, VCR should use these libraries to hook into the HTTP request
so that an appropriate response can be chosen _at request time_.

To get this to work I had to rewrite a large portion of VCR's
internals. After about [70 commits](https://github.com/myronmarston/vcr/compare/e36ed0e812b3a1650090d011d1bf972ae503ad79...221647b75d5aaa105472bd5c2f1d97a8c6b58a9a),
the refactoring, and the new features it enabled, was complete.
It was, if nothing else, an intersting exercise in how to safely
do a large refactoring. I kept the test suite passing all along
the way. I don't think I can emphasize enough how important a
good test suite was to making this possible.

The great thing about this rewrite is that it de-couples VCR
from the declarative APIs of the libraries it integrates with.
When I want to add a new feature to VCR, I no longer have to try
to get a supporting API added to FakeWeb, WebMock and Typhoeus--I
can just add it to VCR itself.

## Request matching in VCR 2.0

In VCR 2.0, a request matcher is simply an object that responds to
`#call` with two arguments and returns `true` if the given requests
should be considered identical, or `false` if they should not be
considered identical.

The simplest request matcher is probably a lambda:

{% gist 1272818 lambda_matcher.rb %}

You can also register it as a named matcher and use the name
in your `:match_requests_on` option:

{% gist 1272818 register_matcher.rb %}

In fact, this is exactly how the [built-in request
matchers](https://github.com/myronmarston/vcr/blob/v2.0.0.beta1/lib/vcr/request_matcher_registry.rb#L64-71)
(`:method`, `:uri`, `:host`, `:path`, `:headers` and `:body`)
work now.

Finally, for the specific case of URIs with non-deterministic
query parameters, VCR provides a simple way to create a request
matcher:

{% gist 1272818 uri_without_timestamp.rb %}

This is only the tip of the iceberg. You can match requests on
specific portions of the request body or headers. I can imagine
people using this to wrap up the specific set of matchers used
for requests to a particular API into a single matcher
that simply delegates to the desired matchers--that way, you can
write `:match_requests_on => [:amazon]` rather than
`:match_requests_on => [:method, :uri_without_signing, :body]` (or whatever).

Check out the [relish docs](https://www.relishapp.com/myronmarston/vcr/v/2-0-0-beta1/docs/request-matching)
for fuller examples.

If you've had problems with how VCR does request matching in the past,
or if you think this sounds useful, please give this beta a try. There
are a number of other changes, too--check out the
[changelog](https://www.relishapp.com/myronmarston/vcr/v/2-0-0-beta1/docs/changelog) for
the full story.

[^foot]: Consider that URI stands for [Uniform Resource
Identifier](http://en.wikipedia.org/wiki/Uniform_Resource_Identifier).
Authentication and request signing have nothing to do with identifiying
the requested resource. These are orthogonal concerns that should be
expressed orthogonally in the HTTP request headers.
