---
layout: dev_post
title: Thoughts on Mocking
section: dev-blog
contents_class: medium-wide
---

I've been thinking a lot about different styles of TDD recently,
particularly the mockist vs. classical schools identified by
Martin Fowler in his classic article, [Mocks Aren't
Stubs](http://martinfowler.com/articles/mocksArentStubs.html).

I personally tend to favor a more mockist style of testing, but
I've come to realize that mockist testing needs to go
hand-in-hand with a particular school of OO design, and on many
projects a classical testing approach would work far better.

My friend [Carlos](http://cohitre.com/) recently came to me with
some questions about how mocking should be used, and expressed
frustration at how brittle the mock-based tests on his current
project are. As he describe it, the mocks caused the tests to
be coupled to the implementation, and thus made refactoring
very difficult. Martin Fowler also [discusses this
problem](http://martinfowler.com/articles/mocksArentStubs.html#CouplingTestsToImplementations)
in his article.

However, I don't think it's that simple. Mocking has often
made it easier for me to refactor. And really, all tests
have some level of coupling to the system-under-test, since
it makes certain assumptions about how the code works or what
side effects result from a particular action. I've developed a
theory recently:

> Mock-based tests are more coupled to the **interfaces** in
> your system, while classical tests are more coupled to
> the **implementation** of an object's collaborators.

A mock-based test will verify the message the object-under-test
sends to its collaborator (i.e. the interface). In contrast,
in a classical test, one would typically allow the
object-under-test to call a real method on a real collaborator,
and then make an assertion about how that changes the state
of the collaborator or one of the collaborator's collaborators.
Thus, this kind of classical test contains knowledge of (and
is coupled to) the implementation of the collaborator--it has
to know what the collaborator does in order to make an assertion
about how it affects the state of the world.

These different kinds of coupling lend themselves to different
kinds of change. With a classical test, you can refactor the
interface between the object-under-test and a collaborator,
and the test will continue to pass just fine. However, if you
change how the collaborator is implemented--and in particular,
how the state change is exposed--then your test will likely
break. In constrast, with a mockist test, you can completely
change the collaborator all you want without breaking the
test as long as you keep the interface the same.

## An Example

Let's look at a simple example to make this more concrete.
We've got a `User` entity that delegates persistence to a
collaborator and provides an `#archive!` method:

{% codeblock user.rb %}
class User
  def initialize(id, persistence = Persistence.new)
    @id, @persistence = id, persistence
  end

  attr_reader   :id, :persistence
  attr_accessor :archived_at

  def archive!
    self.archived_at = Time.now
    persistence.save(self)
  end

  def attributes
    { "archived_at" => archived_at }
  end
end

class Persistence
  def redis
    @redis ||= Redis.new
  end

  def save(user)
    redis.set("users:#{user.id}", JSON.dump(user.attributes))
  end
end
{% endcodeblock %}

Here's how we might test the `#archive!` method using a classical
test and a mockist test:

{% codeblock user_spec.rb %}
describe User, "#archive!" do
  context 'using a mockist test' do
    it 'saves the user with the archived_at timestamp set' do
      persistence = mock("Persistence")
      user = User.new(23, persistence)

      persistence.should_receive(:save) { |u| u.archived_at.should_not be_nil }
      user.archive!
    end
  end

  context 'using a classical test' do
    it 'saves the user with the archived_at timestamp set' do
      user = User.new(23)
      user.archive!

      attributes_json = user.persistence.redis.get("users:23")
      JSON.load(attributes_json).fetch("archived_at").should_not be_nil
    end
  end
end
{% endcodeblock %}

Which test is less brittle in this highly contrived example? It depends.
If you decide to change the persistence interface (e.g. so that `#save`
is renamed as `#persist`, or whatever), then the mockist test will
break, but the classical test can continue to pass unchanged. On the
other hand, if you decide to change the persistence implementation
(e.g. so that it's saving to a relational database, or whatever), then
the classical test will break, but the mockist test will continue to
pass unchanged, as long as you preserve the `#save` interface.

## Conclusion

With these observations in hand, I think we can draw conclusions about
what sorts of codebases work well with mockist tests. Mocking works
really well when the interfaces between objects in your system are
stable and rarely change. From experience, I've seen two primary
factors affecting the stability of interfaces: 

1. The size of the interfaces. Large interfaces become unwieldy over
   time while small, focused interfaces serve a single purpose well
   and rarely need to change.
2. The extent to which your interfaces speak in the language of your
   application domain rather than the language of your technical
   infrastructure. This allows you to change large portions of your
   technical infrastructure without needing many changes to the
   interfaces between your domain objects.

If your codebase doesn't feature these kinds of interfaces, mocking
is unlikely to work well for you and you're probably better off
using classical testing techniques.

