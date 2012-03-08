---
layout: dev_post
title: Building an Around Hook Using Fibers
section: dev-blog
contents_class: medium-wide
---

Ruby 1.9's [fibers](http://ruby-doc.org/core-1.9.3/Fiber.html) have
lots of interesting uses. Recently, I realized that they can be used
to build an around hook out of separate before and after hooks.

RSpec provides an `around(:each)` hook but has no equivalent
`around(:all)` hook. Let's build one!

First, we'll start with a contrived example. We have some examples in a group
that all need to run with a different working directory. Here's
how we can manage this with the existing `before(:all)` and
`after(:all)` hooks:

{% codeblock chdir_spec.rb %}
describe "Changing to the tmp/foo directory" do
  before(:all) do
    @orig_dir = Dir.pwd
    Dir.chdir("tmp/foo")
  end

  after(:all) do
    Dir.chdir(@orig_dir)
  end

  it "changes the directory for all examples in this group" do
    Dir.pwd.should eq(File.expand_path("../tmp/foo", __FILE__))
  end
end
{% endcodeblock %}

`Dir.chdir` has two forms. The form above changes the directory for
all subsequent code. The other form takes a block, and changes the
directory for the duration of the block. This makes it an idea candidate
for an around hook. Here's what we'd like to do instead:

{% codeblock chdir_spec.rb %}
describe "Changing to the tmp/foo directory" do
  around(:all) do |group|
    Dir.chdir("tmp/foo", &group)
  end

  it "changes the directory for all examples in this group" do
    Dir.pwd.should eq(File.expand_path("../tmp/foo", __FILE__))
  end
end
{% endcodeblock %}

Conceptually, you can think of a fiber as a thread, but rather than the
OS or VM scheduling it, you manually switch back and forth. Unlike with
a thread, you don't have to worry about race conditions when modifying
shared process memory, since all context switches are manul.

Our around hook needs to have its own sequence of execution that gets
interrupted in the middle and then resumed; thus, the entire thing
needs to run in its own fiber.  Here's a first pass at that:

{% codeblock chdir_spec.rb %}
require 'fiber'

module AroundAllHook
  def around(scope, &block)
    # let RSpec handle around(:each) hooks...
    return super(scope, &block) unless scope == :all

    group = self
    fiber = nil
    before(:all) do
      fiber = Fiber.new(&block)
      fiber.resume(group)
    end

    after(:all) do
      fiber.resume
    end
  end
end

describe "Changing to the tmp/foo directory" do
  extend AroundAllHook

  around(:all) do |group|
    Dir.chdir("tmp/foo") { |group| Fiber.yield }
  end

  it "changes the directory for all examples in this group" do
    Dir.pwd.should eq(File.expand_path("../tmp/foo", __FILE__))
  end
end
{% endcodeblock %}

So how does this work? Taking it line by line:

* `fiber = nil` creates a local variable. This is important so that the
  same fiber instance is in scope in both the before hook and the after
  hook. This is possible because ruby blocks are a kind of
  [closure][1] and thus retain a binding to that variable. It's
  important that we use a local variable here and not an instance
  variable. The local variable causes the fiber to be shared between
  just this pair of hooks. If you used an instance variable, it would
  not work when someone defined multiple `around(:all)` hooks in the
  same group, because the fiber would be shared between multiple
  before/after pairs. We need one fiber per pair.
* `before(:all)` and `after(:all)` use the existing RSpec hooks. We can
  assume they'll be available in this context because this module is
  intended to be extended onto an example group.
* Within the before hook, we create a new fiber: `fiber =
  Fiber.new(&block)`. The block is passed to the fiber so that it runs
  entirely within it.
* `fiber.resume(group)` starts the fiber, and passes the example group
  as an argument. That will cause it to be the yielded argument in the block.
* Within the declared `around(:all)` hook, we have `Dir.chdir("tmp/foo")
  { |group| Fiber.yield }`. This changes the directory, then uses
  `Fiber.yield` to return control to the root fiber[^foot]. This allows
  RSpec to do what it normally does immediately after a `before(:all)`
  hook: it runs the examples in the group.
* Once the examples finish, RSpec invokes our `after(:all)` hook. In our
  hook, we simply resume the fiber: `fiber.resume`. This returns
  execution to the point immediately after the `Fiber.yield` in the
  `Dir.chdir` block. Thus, it allows the block to complete and
  `Dir.chdir` returns the working directory to its original value
  when the block completes.

If you're not following what `Fiber#resume` and `Fiber.yield` do, 
check out the [fiber ruby docs](http://ruby-doc.org/core-1.9.3/Fiber.html).
They have a good explanation and a simpler example.

At this point, we have a working `around(:all)` hook, but it's a pretty
leaky abstraction. The user of this hook has to know to call
`Fiber.yield` in the middle of his hook; otherwise they'll get a
`FiberError` ("dead fiber called") when RSpec runs the `after(:all)` hook.

Let's improve this API. First, we'll implement a `#run_examples` method
that simply delegates to `Fiber.yield`:

{% codeblock chdir_spec.rb %}
require 'delegate'

module AroundAllHook
  class FiberAwareGroup < SimpleDelegator
    def run_examples
      Fiber.yield
    end
  end
end
{% endcodeblock %}

Now we can pass a `FiberAwareGroup` instance to `fiber.resume`:

{% codeblock chdir_spec.rb %}
before(:all) do
  fiber = Fiber.new(&block)
  fiber.resume(FiberAwareGroup.new(group))
end
{% endcodeblock %}

Finally, we can use this in the `around(:all)` hook:

{% codeblock chdir_spec.rb %}
around(:all) do |group|
  Dir.chdir("tmp/foo") { group.run_examples }
end
{% endcodeblock %}

Note that we could have defined `run_examples` as a singleton
method on `group`, or defined the method in a module
that we extend onto `group`, but I prefer delegation for
cases like these. Both of the other techniques permanently modify
the object and thus leak the `#run_examples` method into other
contexts where it no longer makes sense.

This is an improvement from requiring users to call `Fiber.yield`, but
we can take it a step further. We'd like to be able to treat the yielded
group as a proc, like so:

{% codeblock chdir_spec.rb %}
around(:all) do |group|
  Dir.chdir("tmp/foo", &group)
end
{% endcodeblock %}

We simply need to define an appropriate `#to_proc`:

{% codeblock chdir_spec.rb %}
class FiberAwareGroup < SimpleDelegator
  def run_examples
    Fiber.yield
  end

  def to_proc
    proc { run_examples }
  end
end
{% endcodeblock %}

To see the final code, check out the little
[microgem](https://gist.github.com/2005175) I put together.

[1]: http://en.wikipedia.org/wiki/Closure_(computer_science)

[^foot]: I was going use the term "main fiber" instead (since
         "main thread" is a standard term), but the [ruby
         docs](http://ruby-doc.org/core-1.9.3/Fiber.html#method-c-current)
         use the term "root fiber" so I figured I would too :).

