---
layout: dev_post
title: Cassettes in VCR 2.0
section: dev-blog
contents_class: medium-wide
published: true
---

The first beta release of VCR 2.0 was focused on [improving how the
request matchers work](/n/dev-blog/2011/10/custom-request-matchers-in-vcr-2-0)
so users can easily customize them to their needs.

The second beta, released yesterday, includes a bunch of changes to the
cassette format. Unfortunately, cassettes recorded with VCR 1.x
are not compatible with VCR 2.0. I imagine this may make upgrading
painful for some users (though, I'm hopeful the pain will be minimal),
and I thought it worthwhile to explain the reasons for all the changes.

## YAML issues

[YAML](http://yaml.org/) is a great serialization format. It's the most
human-readable and human-editable format I know of (both of which I
consider to be very important for VCR). It's been the only serialization
format for VCR cassettes from the first release.

However, it's not without issues. Syck, the YAML engine in ruby 1.8,
has a number of unfortunate bugs. I've had
[multiple](https://github.com/myronmarston/vcr/issues/4)
[reports](https://github.com/myronmarston/vcr/issues/39)
of syck segfaulting due to particular data in the VCR cassette. In addition, it
[removes spaces from whitespace-only
lines](https://gist.github.com/815754). A string like `"1\n
\n2"`, when round-tripped through syck, results in `"1\n\n2"`--a string
of one less character. This can cause problems for HTTP clients that
depend on the "Content-Length" header accurately matching the length of
the response body. Mechanize, for example, will raise an error.

Psych, the new YAML engine in ruby 1.9 written by
[tenderlove](http://twitter.com/tenderlove), is much improved. Since
1.7.0, VCR has attempted to use psych when it is avaiable. However,
psych also occasionally has [segfaulting](https://github.com/myronmarston/vcr/issues/74)/[memory
corruption](https://github.com/myronmarston/vcr/issues/83) issues.

## New Serializers!

VCR 2.0 allows you to choose from several different serializers,
or even provide your own. This can be useful to work around
an issue with either sych or psych, or simply because you prefer
another format (e.g. JSON). VCR 2.0 now has 4 built in serializers:

* YAML
* Syck
* Psych
* JSON

YAML is still the default, and uses the standard library
`YAML` after requiring "yaml".  This could wind up using
either syck or psych, depending upon your ruby interpreter.
The Syck and Psych serializers are useful as a way to force those libraries
to be used. Syck is particularly useful when you have a project
that needs to run on 1.8 and 1.9, so that the same YAML library
gets used regardless of the ruby interpreter version. The
JSON serializer uses [multi\_json](https://github.com/intridea/multi_json)
so that it supports a variety of JSON backends.

Here's how to pick a serializer:

{% codeblock serialize_with_json.rb %}
# use the JSON serializer for a particular cassette...
VCR.use_cassette("example", :serialize_with => :json) do
  # make an HTTP request
end

# ...or use the JSON serializer for all cassettes
VCR.configure do |config|
  config.default_cassette_options = { :serialize_with => :json }
end
{% endcodeblock %}

## Providing Your Own Custom Serializer

It's fairly trivial to provide your own serializer. You need to provide
an object that implements three methods:

* `file_extension`
* `serialize(hash)`
* `deserialize(string)`

Here's an example using ruby's marshal library:

{% codeblock marshal_serializer.rb %}
serializer = Object.new
serializer.instance_eval do
  def file_extension
    "rb_marshal"
  end

  def serialize(hash)
    Marshal.dump(hash)
  end

  def deserialize(string)
    Marshal.load(string)
  end
end

VCR.configure do |config|
  config.cassette_serializers[:marshal] = serializer
  config.default_cassette_options = { :serialize_with => :marshal }
end
{% endcodeblock %}

## Cassettes are More Portable

VCR 1.x serialized some structs directly to YAML. This caused
the classes (`VCR::HTTPInteraction`, `VCR::Request` and `VCR::Response`)
to be named directly in the cassette. In 2.0, VCR passes a simple
hash to the serializer, so these class names no longer show up in the
cassette file. Besides making it possible to use different serializers,
this also makes the VCR cassette format much more portable. You can
read and use a VCR cassette without loading VCR now!  It opens up the
possibility to use a VCR cassette from other languages as well.

## Now With Less Normalization

VCR 1.x extensively normalized each HTTP Interaction. VCR
originally only worked with FakeWeb and Net::HTTP. As I
expanded VCR to work with many other libraries, I tried to
ensure that the cassette that resulted from a particular
set of recorded HTTP interactions would be the same, regardless
of the HTTP client library or stubbing library used. At the time,
it made sense to me that since a VCR cassette is agnostic
about which HTTP client library was used, it should be the same
for the same set of HTTP interactions. Net::HTTP normalizes header
keys to lower case, so VCR 1.x performed the same normalization on
the headers stored in the cassette. On playback, it would de-normalize
as necessary; if the header key was `content-type`, it would be
de-normalized as `Content-Type`. Theoretically, this would have allowed
you to change your implementation to use a different HTTP library,
and the VCR cassette should continue to playback just fine.

Unfortunately, the de-normalization doesn't always work properly.
If a header is recorded as `etag`, it gets de-normalized to `Etag`
even though it may originally have been `ETag`. This is in fact
an [issue when using VCR with
Fog](https://github.com/fog/fog/issues/434).

So, in VCR 2.0, I've removed this normalization. You'll see more
variance in the data that gets recorded by an identical HTTP request
from different HTTP libraries.

## New `recorded_at` metadata

VCR 2.0 now includes a `recorded_at` timestamp for each
HTTP Interaction. This allows the `re_record_interval`
cassette option to work much more accurately. Previously,
VCR used the cassette file's modification time, but this
may not be accurate, especially when the file on disk changes
due to your source control (i.e. if you change git branches
or whatever).

## New `recorded_with` metadata

VCR 2.0 also includes a bit of metadata about the cassette as
a whole: `recorded_with` will be a string like `"VCR 2.0.0"`.
Theoretically, if any other tool like VCR comes along and wanted to
adopt the same fixture format, it could use this to identify itself as
well.

I've wanted to make changes to the VCR cassette format for awhile, but
have held off for fear of making breaking changes. This bit of metadata
should make future format changes much easier to make in a
backwards-compatible way, as it will identify the format version that was used
to record the cassette so it can be easily and automatically upgraded.

## Upgrading

The [upgrade notes](https://www.relishapp.com/myronmarston/vcr/docs/upgrade)
contain instructions for how to upgrade from VCR 1.x. If you're curious
to see examples of how the cassette format changed, take a look at a
[1.x cassette](https://github.com/myronmarston/vcr/blob/v1.11.3/spec/fixtures/not_1.9.1/cassette_spec/example.yml)
compared to the same cassette in [2.0 format](https://github.com/myronmarston/vcr/blob/v2.0.0.beta2/spec/fixtures/cassette_spec/example.yml).

