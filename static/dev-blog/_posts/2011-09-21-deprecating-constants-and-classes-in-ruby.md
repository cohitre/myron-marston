---
layout: dev_post
title: Deprecating Constants (and Classes) in Ruby
section: dev-blog
contents_class: medium-wide
---

Ruby has great tools for deprecating obselete code.  One of my favorite
techniques is one I rarely see: using `const_missing` to deprecate
constants, and, by extension, classes and modules.

Consider this code:

{% gist 1225953 my_gem_config.rb %}

At a later time, you decide you would rather name this class
`MyGem::Configuration`.  It's easy enough to change the name,
but you may break backwards compatiblity with people who have
references to `MyGem::Config` in their code.

`const_missing` really comes in handy here:

{% gist 1225953 my_gem_configuration.rb %}

This allows existing code that references `MyGem::Config` to
continue to work, and warns the user about their use of the
deprecated constant.
