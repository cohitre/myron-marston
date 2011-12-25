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

{% codeblock my_gem/config.rb %}
module MyGem
  class Config
  end
end
{% endcodeblock %}

At a later time, you decide you would rather name this class
`MyGem::Configuration`.  It's easy enough to change the name,
but you may break backwards compatiblity with people who have
references to `MyGem::Config` in their code.

`const_missing` really comes in handy here:

{% codeblock my_gem/configuration.rb %}
module MyGem
  class Configuration
  end

  def self.const_missing(const_name)
    super unless const_name == :Config
    warn "`MyGem::Config` has been deprecated. Use `MyGem::Configuration` instead."
    Configuration
  end
end
{% endcodeblock %}

This allows existing code that references `MyGem::Config` to
continue to work, and warns the user about their use of the
deprecated constant.
