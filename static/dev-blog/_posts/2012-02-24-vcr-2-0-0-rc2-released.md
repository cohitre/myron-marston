---
layout: dev_post
title: VCR 2.0.0 RC2 Released!
section: dev-blog
contents_class: medium-wide
---

I've just released VCR 2.0.0.rc2. This is (hopefully) the last stop
before the final 2.0.0 relesae. If there are no major issues, I plan
to release 2.0.0 next week some time. Please give 2.0.0.rc2 a try with
your test suite!

On to what's been changed since RC1...

## Yard API Docs

VCR has used its cucumber suite, hosted on [relish](http://relishapp.com/myronmarston/vcr),
as documentation for a good year or so. I've received many positive
comments about the docs, and how useful all the executable examples are.

The relish docs are great at demonstrating each high-level feature
through an exectuble example, but they're not so great at documenting
the interface for particular objects. VCR now has many hooks, and it's
hard to document the full interface of the objects yielded to those
hooks on relish.

So, with the help of [Benjamin Oakes](http://www.benjaminoakes.com/)
(and many patient answers to my questions from
[Loren Segal](http://gnuu.org/)), VCR now has proper
[YARD API docs](http://rubydoc.info/github/myronmarston/vcr/frames).

## Hook Filters

The `before_http_request`, `after_http_request`, and `around_http_request` hooks
all now accept zero or more filters as an argument. "Filters" are simply
objects that respond to `#to_proc`. Before invoking the hook, VCR will
call the filter procs, and only continue invoking the hook if all of the
filter procs return a truthy value.

On top of that, the request object has gained some additional predicate methods
in the context of these hooks: `#real?`, `#ignored?`, `#stubbed?`,
`#recordable?` and `#unhandled?`. You can use these in a hook to
conditionally run logic for only certain types of requests. For example,
to do something before all real requests:

{% codeblock request_hook.rb %}
VCR.configure do |c|
  c.before_http_request do |request|
    if request.real?
      do_something_with(request)
    end
  end
end
{% endcodeblock %}

Or, if you prefer (and I certainly do!), using a filter:

{% codeblock request_hook.rb %}
VCR.configure do |c|
  c.before_http_request(:real?) do |request|
    do_something_with(request)
  end
end
{% endcodeblock %}

This feature is also quite useful when used in conjunction with an
`around_http_request` hook to globally handle requests to a particular
host. Here's the code example I put in the [2.0.0 RC1 release
announcement](/n/dev-blog/2011/12/vcr-2-0-0-rc-released):

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

Here's how you could clean this up a bit with a hook filter:

{% codeblock handle_geocoding_requests.rb %}
VCR.configure do |c|
  c.around_http_request(lambda { |r| r.uri =~ /api.geocoder.com/ }) do |request|
    # extract an address like "1700 E Pine St, Seattle, WA"
    # from a query like "address=1700+E+Pine+St%2C+Seattle%2C+WA"
    address = CGI.unescape(URI(request.uri).query.split('=').last)
    VCR.use_cassette("geocoding/#{address}", &request)
  end
end
{% endcodeblock %}

## Improved Excon Support

VCR has supported Excon for a while, but the integration has [had a few
issues](http://groups.google.com/group/ruby-fog/browse_thread/thread/737295ebb42e67d1/df2effe4cceffc68).
I myself have experienced some of this pain when I tried to use VCR to
help test some code that uses Fog to communicate with S3.

I finally dug in and worked through the issues. There were a couple bugs
on the VCR side and one bug in Excon's stubbing support. I believe VCR
should work seemlessly with any excon request now, including with Fog.

## Debug Logging

Sometimes VCR doesn't work the way you would expect, and prior to now,
there hasn't been a good built-in way to get insight into what VCR was
doing. VCR now has a new `debug_logger` option. Set it to any object
with a `puts` method:

{% codeblock debug_logging.rb %}
VCR.configure do |c|
  c.debug_logger = $stdout
  # or
  c.debug_logger = File.open('log/vcr.log')
end
{% endcodeblock %}

## New `preserve_exact_body_bytes` option

Some HTTP servers are not well-behaved and respond with invalid data: the response body may
not be encoded according to the encoding specified in the HTTP headers, or there may be bytes
that are invalid for the given encoding. The YAML and JSON serializers are not generally
designed to handle these cases gracefully, and you may get errors when the cassette is serialized
or deserialized. Also, the encoding may not be preserved when round-tripped through the
serializer.

VCR now has a a `preserve_exact_body_bytes` option to help deal with
cases like these. You can set it globally:

{% codeblock preserve_exact_body_bytes.rb %}
VCR.configure do |c|
  c.preserve_exact_body_bytes do |http_message|
    http_message.body.encoding.name == 'ASCII-8BIT' ||
    !http_message.body.valid_encoding?
  end
end
{% endcodeblock %}

...or you can force the option for a particular cassette:

{% codeblock preserve_exact_body_bytes.rb %}
VCR.use_cassette("example", :preserve_exact_body_bytes => true) do
  # ...
end
{% endcodeblock %}

When you set this opion, VCR will base64 encode the body of the request
or response during serialization, in order to preserve the bytes
exactly.

## What's next

I plan to release VCR 2.0.0 final in the next week or two. Please give
VCR 2.0.0.rc2 a try and let me know if you have any issues!
