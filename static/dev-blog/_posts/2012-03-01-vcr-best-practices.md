---
layout: dev_post
title: VCR Best Practices
section: dev-blog
contents_class: medium-wide
published: false
---

## Commit Your Cassettes to Source Control

This makes it possible to checkout an old revision of your project
and still have fast, deterministically passing tests. This can be
especially important when you need to use `git blame` to go back through
your source history.

If you're worried about HTTP responses changing (and potentially
breaking your library or app), consider using the
[`:re_record_interval`](http://relishapp.com) option to periodically
re-record your cassettes. Alternately, you might set up your CI server
so that it deletes all of the cassettes before running your tests so
that it is always integrating with real HTTP requests.

## Don't Allow Private Credentials in Your Cassettes

The old mantra that you shouldn't be storing API keys and other private
credentials in source control still applies. This is especially
important if you are building an open source gem. VCR provides an option
specifically to help with this:

{% codeblock vcr_setup.rb %}
# Note: .api_key should not be kept in source control
if File.exist?('.api_key')
  MyApiClient.api_key = File.read('.api_key')
else
  warn "Using a fake API key; you will not be able to record new HTTP requests using VCR."
  MyApiClient.api_key = 'fake_api_key'
end

VCR.configure do |c|
  c.filter_sensitive_data('<API_KEY>') { MyApiClient.api_key }
end
{% endcodeblock %}

When VCR records a request, it will replace all instances of the API key
with `<API_KEY>` in the cassette. During playback, it will put the value
returned by `MyApiClient.api_key` back in place of the placeholder
string (e.g. `<API_KEY>`), so that the requests in the cassette match
the requests that get made by your tests.

## Use `define_cassette_placeholder` to Define Variables for Unique Strings

The `filter_sensitive_data` configuration option has been in VCR for
over a year. While it was designed for use with private credentials,
I've often found myself using it to put "variables" in my cassettes
to make them a bit dynamic without resorting to ERB. VCR 2 now provides
`define_cassette_placeholder` as an alias for `filter_sensitive_data`.

Consider the case where you are integrating with a new API that has not
yet launched. It's currently in beta and available at `beta.api.acme.com`.
Once it launches, it will be available at `api.acme.com`, and
`beta.api.acme.com` will no longer be available. The
`define_cassette_placeholder` config option works perfectly to put a
variable in place of the host:

{% codeblock vcr_setup.rb %}
VCR.configure do |c|
  c.define_cassette_placeholder('<ACME_API_HOST>') { Acme::Client.api_host }
end
{% endcodeblock %}

With this in place, your cassettes will be recorded with
`<ACME_API_HOST>` as a placeholder, and they will continue to playback
just fine after the API has moved and you have updated
`Acme::Client.api_host`.

