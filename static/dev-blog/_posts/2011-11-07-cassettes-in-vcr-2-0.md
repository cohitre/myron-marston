---
layout: dev_post
title: Cassettes in VCR 2.0
section: dev-blog
contents_class: medium-wide
published: false
---

The first beta release of VCR 2.0 was focused on [improving how VCR matches
requests](/n/dev-blog/2011/10/custom-request-matchers-in-vcr-2-0) to help
users deal with APIs that have requests that aren't easily identified by
method and URI.

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
has a number of unfortunate bugs. I've had [reports of syck segfaulting
on users](https://github.com/myronmarston/vcr/issues/4)
due to particular data in the VCR cassette. In addition, it
truncates whitespace on lines of only whitespace. A string like `"1\n
\n2"`, when round-tripped through syck, results in `"1\n\n2"`--a string
of one less character. This can cause problems for HTTP clients that
depend on the "Content-Length" header accurately matching the length of
the response body. Mechanize, for example, will raise an error.

Psych, the new YAML engine in ruby 1.9 written by
[@tenderlove](http://twitter.com/tenderlove), is much improved. Since
VCR 1.7.0, 

## New Serializers!

## Now with less normalization

## 
