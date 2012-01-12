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

{% codeblock configuration.rb %}
# VCR 1.x
VCR.config do |c|
  c.cassette_library_dir = 'cassettes'
  c.stub_with :fakeweb, :typhoeus
end

# VCR 2.0
VCR.configure do |c|
  c.cassette_library_dir = 'cassettes'
  c.hook_into :fakeweb, :typhoeus
end
{% endcodeblock %}

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

{% codeblock log_request.rb %}
VCR.configure do |c|
  c.after_http_request do |request, response|
    Logger.log_http_request(request, response)
  end
end
{% endcodeblock %}

You can also use a request hook to globally handle all requests
made to a specific API:

{% codeblock handle_geocoding_requests.rb %}
VCR.configure do |c|
  c.around_http_request do |request|
    uri = URI(request.uri)
    if uri.host == 'api.geocoder.com'
      # extract an address like "1700 E Pine St, Seattle, WA"
      # from a query like "address=1700+E+Pine+St%2C+Seattle%2C+WA"
      address = CGI.unescape(uri.query.split('=').last)
      VCR.use_cassette("geocoding/#{address}", &request)
    else
      request.proceed
    end
  end
end
{% endcodeblock %}

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

{% codeblock vcr_setup.rb %}
VCR.configure do |c|
  c.ignore_localhost = true # to ignore 127.0.0.1 and localhost requests

  # or...

  c.ignore_hosts 'foo.com', 'bar.com'
end
{% endcodeblock %}

This worked great for most people, but some wanted
to [selectively ignore localhost requests based on
port](https://github.com/myronmarston/vcr/issues/42). VCR 2.0
now lets you ignore a request based on _anything_, by providing
a block that returns a truthy value if the given request
should be ignored. Here's how you can ignore only localhost requests
to port 7500:

{% codeblock ignore_request.rb %}
VCR.configure do |c|
  c.ignore_request do |request|
    uri = URI(request.uri)
    uri.host == 'localhost' && uri.port == 7500
  end
end
{% endcodeblock %}

## Improved Unhandled Request Error Messages

If you've used VCR 1.x, you've undoubtedly gotten an error like this:

{% codeblock vcr_1_x_error.txt lang:sh %}
Real HTTP connections are disabled. Unregistered request: GET
http://api.somehost.com/widgets.  You can use VCR to automatically
record this request and replay it later.  For more details, visit
the VCR documentation at: http://relishapp.com/myronmarston/vcr/v/1-11-3
(FakeWeb::NetConnectNotAllowedError)
{% endcodeblock %}

You get this kind of error when a request is made that VCR does not
know how to handle. There are a lot of different ways you can fix the
error, but the message doesn't give you much help.

In VCR 2.0, you'll get a more helpful error message:

{% codeblock example_error.txt lang:sh %}
================================================================================
An HTTP request has been made that VCR does not know how to handle:
  GET http://api.somehost.com/widgets

VCR is currently using the following cassette:
  - cassettes/widgets.yml
  - :record => :once
  - :match_requests_on => [:method, :uri]

Under the current configuration VCR can not find a suitable HTTP interaction
to replay and is prevented from recording new requests. There are a few ways
you can deal with this:

  * You can use the :new_episodes record mode to allow VCR to
    record this new request to the existing cassette [1].
  * If you want VCR to ignore this request (and others like it), you can
    set an `ignore_request` callback [2].
  * The current record mode (:once) does not allow new requests to be recorded
    to a previously recorded cassette. You can delete the cassette file and re-run
    your tests to allow the cassette to be recorded with this request [3].
  * The cassette contains 1 HTTP interaction that has not been
    played back. If your request is non-deterministic, you may need to
    change your :match_requests_on cassette option to be more lenient
    or use a custom request matcher to allow it to match [4].

[1] https://www.relishapp.com/myronmarston/vcr/v/2-0-0-rc1/docs/record-modes/new-episodes
[2] https://www.relishapp.com/myronmarston/vcr/v/2-0-0-rc1/docs/configuration/ignore-request
[3] https://www.relishapp.com/myronmarston/vcr/v/2-0-0-rc1/docs/record-modes/once
[4] https://www.relishapp.com/myronmarston/vcr/v/2-0-0-rc1/docs/request-matching
================================================================================
{% endcodeblock %}

## Integration with RSpec 2 Metadata

[Ryan Bates](http://twitter.com/rbates) had this [great
idea](https://gist.github.com/1212530) to
integrate VCR with RSpec 2 using metadata. VCR 2.0 now
provides direct support for this:

{% codeblock vcr_rspec_metadata.rb %}
VCR.configure do |c|
  c.configure_rspec_metadata!
end

RSpec.configure do |c|
  # so we can use `:vcr` rather than `:vcr => true`;
  # in RSpec 3 this will no longer be necessary.
  c.treat_symbols_as_metadata_keys_with_true_values = true
end

# apply it to an example group
describe MyAPIWrapper, :vcr do
end

describe MyAPIWrapper do
  # apply it to an individual example
  it "does something", :vcr do
  end

  # set some cassette options
  it "does something", :vcr => { :record => :new_episodes } do
  end

  # override the cassette name
  it "does something", :vcr => { :cassette_name => "something" } do
  end
end
{% endcodeblock %}

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

{% codeblock exclusive_cassette.rb %}
VCR.use_cassette('my_cassette', :exclusive => true) do
  # ...
end
{% endcodeblock %}

## VCR 2.0.0 Final

I plan to release VCR 2.0.0 final in a couple of weeks. Please give
the RC a try and give me feedback!
