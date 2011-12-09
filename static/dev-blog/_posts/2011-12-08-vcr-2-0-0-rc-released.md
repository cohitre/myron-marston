---
layout: dev_post
title: VCR 2.0.0 RC Released!
section: dev-blog
contents_class: medium-wide
---

I've just released the release candidate for VCR 2.0.0. There's lots of
new goodness. This blog post is a bit of an "extended" change log detailing
most of the interesting changes from VCR 1.x.

## What's been removed

Support for Ruby 1.8.6 and 1.9.1 has been dropped. It doesn't make sense
to keep supporting these versions, especially since I use [travis-ci](http://travis-ci.org/#!/myronmarston/vcr)
for my CI builds and it no longer supports 1.8.6 and 1.9.1.

There are several old deprecated APIs that have been removed. This is
unlikely to affect anyone since I believe they have all been deprecated
for over a year. I won't detail them here. If you're running a fairly
recent 1.x release without any warnings then this shouldn't affect you
at all.

VCR 1.x supported regexes that were manually inserted in a cassette in
place of a URI. This support has been dropped. VCR 2.0 supports [custom request
matchers](/n/dev-blog/2011/10/custom-request-matchers-in-vcr-2-0#request_matching_in_vcr_20)
which are much more flexible then
the regex support in VCR 1.x. You could even re-implement the regex
support using a custom request matcher in a few lines of code if it
is important for your test suite.

## What's been changed

The configuration API has changed slightly:

{% gist 1441616 configuration.rb %}

Your existing configuration will continue to work with a deprecation
warning.

The [cassette format has changed
significantly](/n/dev-blog/2011/11/cassettes-in-vcr-2-0). VCR 1.x
cassettes are not compatible with VCR 2.0. You'll need to either
re-record them or [migrate them to the new
format](https://github.com/myronmarston/vcr/blob/master/Upgrade.md).

Individual HTTP interactions are no longer replayed multiple times
during the use of a single cassette. The new [`:allow_playback_repeats` cassette
option](https://www.relishapp.com/myronmarston/vcr/docs/request-matching/playback-repeats)
can be used to restore the VCR 1.x behavior.

The [Faraday](https://github.com/technoweenie/faraday) integration has
been rewritten. The Faraday integration in VCR 1.x was more than a
little confusing; besides configuring `config.stub_with :faraday`, you
also had to insert `VCR::Middleware::Faraday` in the Faraday middleware
stack and provide a cassette configuration block. In VCR 2.0, you simply
configure `config.hook_into :faraday`, just like for FakeWeb, WebMock,
Typhoeus or Excon. Under the covers, it takes care of inserting the
middleware in the Faraday stack. Alternately, if you want control over
where the VCR middleware goes in the stack, you can opt to insert it
yourself.

## Custom Request Matchers

This is one of the best new features of VCR 2.0. I [blogged about this
previously](/n/dev-blog/2011/10/custom-request-matchers-in-vcr-2-0#request_matching_in_vcr_20),
so I won't belabor it here.

## Swappable (and Custom) Serializers

This is one of the other big new features of VCR 2.0. My [recent blog
post](/n/dev-blog/2011/11/cassettes-in-vcr-2-0#new_serializers)
contains the pertinent details.

## Request Hooks

VCR now provides `before_http_request`, `after_http_request`
and `around_http_request` hooks. These can be used in many ways.
Here's how you could use an `after_http_request` hook to log all
HTTP requests:

{% gist 1446269 log_request.rb %}

You can also use a request hook to globally handle all requests
made to a specific API:

{% gist 1446288 handle_geocoding_requests.rb %}

In an `around_http_request`, you can either treat the request as
a proc (and pass it on to a method that expects a block as `&request`),
or use `request.proceed` to allow the request to continue.

I certainly wouldn't recommend doing this for all requests--you'll often
want to test the same requests getting different responses in different
tests--but for truly stateless APIs that always return the same response
for a given request (such as a geocoder) this can be very handy.

On ruby 1.8 you won't be able to use an `around_http_request` hook
because it uses a fiber; instead you can use separate
`before_http_request` and `after_http_request` to achieve the same
behavior.

## Ignore a Request Based on Anything

VCR 1.x made it simple to ignore a request based on the host:

{% gist 1430657 vcr_setup.rb %}

This worked great for most people, but some wanted
to [selectively ignore localhost requests based on
port](https://github.com/myronmarston/vcr/issues/42). VCR 2.0
now lets you ignore a request based on _anything_, by providing
a block that returns a truthy value if the given request
should be ignored. Here's how you can ignore only localhost requests
to port 7500:

{% gist 1430672 ignore_request.rb %}

## Improved Unhandled Request Error Messages

If you've used VCR 1.x, you've undoubtedly gotten an error like this:

{% gist 1432329 vcr_1_x_error.txt %}

You get this kind of error when a request is made that VCR does not
know how to handle. There are a lot of different ways you can fix the
error, but the message doesn't give you much help.

In VCR 2.0, you'll get a more helpful error message:

{% gist 1432316 example_error.txt %}

## Integration with RSpec 2 Metadata

[Ryan Bates](http://twitter.com/rbates) had this [great
idea](https://gist.github.com/1212530) to
integrate VCR with RSpec 2 using metadata. VCR 2.0 now
provides direct support for this:

{% gist 1441746 vcr_rspec_metadata.rb %}

The old [`use_vcr_cassette`
macro](https://www.relishapp.com/myronmarston/vcr/docs/test-frameworks/usage-with-rspec-macro)
still works. The primary difference is that the macro uses the same
cassette for each example in an example group, while the metadata uses
a different cassette for each individual example.

## Exclusive cassettes

VCR has always allowed you to "nest" cassettes; for example, you may use
a cassette for an entire cucumber scenario and then also use a cassette
in an individual step definition. When you do this, requests may be
handled by an HTTP interaction from the outer cassette if there
is not an HTTP interaction from the inner cassette that matches.

If you do not want to allow the matching to "fall through" to the outer
cassette you can use the new `:exclusive` option:

{% gist 1446331 exclusive_cassette.rb %}

## VCR 2.0.0 Final

I plan to release VCR 2.0.0 final in a couple of weeks. Please give
the RC a try and give me feedback!
