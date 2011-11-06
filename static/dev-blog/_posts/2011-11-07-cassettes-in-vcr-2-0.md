---
layout: dev_post
title: Cassettes in VCR 2.0
section: dev-blog
contents_class: medium-wide
published: false
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

{% gist 1342232 with_json_serializer.rb %}

## Providing Your Own Custom Serializer

It's fairly trivial to provide your own serializer. You need to provide
an object that implements three methods:

* `file_extension`
* `serialize(hash)`
* `deserialize(string)`

Here's an example using ruby's marshal library:

{% gist 1342244 marshal_serializer.rb %}

## Cassettes are More Portable

VCR 1.x serialized some structs directly to YAML. This caused
the classes (`VCR::HTPInteraction`, `VCR::Request` and `VCR::Response`)
to be named directly in the cassette. In 2.0, VCR passes a simple
hash to the serializer, so these class names no longer show up in the
cassette file. Besides making it possible to use different serializers,
this also makes the VCR cassette format much more portable. You can use
read and use a VCR cassette without loading VCR now!  It opens up the
possibility to use a VCR cassette from another language as well.

## Now With Less Normalization

VCR 1.x extensively normalized each HTTPInteraction. VCR
originally only worked with FakeWeb and Net::HTTP. As I
expanded VCR to work with many other libraries, I preserved
the same cassette format

## 
