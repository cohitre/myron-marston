---
layout: dev_post
title: Deprecating a Legacy Subsystem in Rails
section: dev-blog
contents_class: medium-wide
---

A major part of my job in the past year at [SEOmoz](http://www.seomoz.org/)
was a re-write of the [rank-tracking component](http://www.seomoz.org/features)
of SEOmoz PRO. The existing system had major performance and scalability problems,
and [Jeff Pollard](http://bitfluxx.com/) and I were tasked with designing and
and building an internal service to solve all these problems.

Jeff previously [blogged a bit](http://devblog.seomoz.org/2011/10/using-riak-for-ranking-collection/)
about the design of the system, particularly our choice of Riak as the
main data store. One of the other interesting bits to come out of this
project was the way we migrated from the old system to the new system.
We knew it would take at least a couple weeks (although, in the end it
took 3 months!) and it was important that there was ZERO negative customer
impact during the migration period. I came up with a technique that made
it very easy to keep the existing system around in a deprecated state,
and, once all data had been migrated to the new system, remove it
entirely.

## The Goals

We had several goals and constraints for the migration:

* The volume of data to import (billions of MySQL records) was such that a
  single atomic switch to the new system seemed impossible (or, at the very least,
  extremely risky). Thus, we knew we wanted to have a way to run the old
  and new systems side-by-side, and migrate customers over to the new
  system one-by-one.
* The old ranking system used a tangle of SQL views, ActiveRecord models, and
  controller and view logic. There was no value in re-using any of this
  code for the new system. Thus, we wanted to "quarantine" this old code to
  have a clean slate to build out the controller and views for the new
  system (the new system didn't have any ActiveRecord models since it
  relied upon the HTTP API of the service for its data). Once the
  migration was complete, we wanted it to be very easy to remove the old
  system (i.e. by simply deleting the source files from a few
  directories).
* The routes for the existing ranking system were fine, and we wanted to keep
  using them for the new system.
* Previously, we had replaced one of the other subsystems with an
  internal service. For that project, the rails app had a long-running
  branch (as in several months) that integrated with the new service. We
  frequently experienced merge pain for that project. This time, we knew
  we wanted to use a feature flag, and build out the rails side of the
  new system directly in the master branch, with no painful merges.

The solution I came up with worked very well, and I think it can apply
to similar problems in other systems.

## Step 1: Move the models into deprecated directory

First, I made a new directory at `app/models/deprecated` and moved all
the models for the old ranking system there. This quarantined the legacy
code and made it clear that the code was going away soon and no significant
investment should go into refactoring it.

We had to configure rails to recognize this new directory for
auto-loading:

{% codeblock config/application.rb %}
module Cmoz
  class Application < Rails::Application    
    # ...
    config.autoload_paths << "#{config.root}/app/models/deprecated"
    # ...
  end
end
{% endcodeblock %}

## Step 2: Add a feature flag to the user model

The new service was named "silo", so we added a `using_silo` flag
to the user model that defaulted to false.

{% codeblock db/migrate/20110509180019_add_using_silo_to_users.rb %}
class AddUsingSiloToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :using_silo, :boolean, :null => false, :default => false
  end

  def self.down
    remove_column :users, :using_silo
  end
end
{% endcodeblock %}

## Step 3: Turn the old controller into a conditionally extended module

The controller and views were a bit more difficult to deprecate cleanly.
As I mentioned above, we wanted to preserve the existing routes, and I
don't know of a way in rails to route identical requests to different
controllers based on a feature flag on the current user record. Instead,
we kept a single controller, and turned the old controller into a mixin
that we conditionally extended onto the controller instance.

We started with a controller that was roughly like this:

{% codeblock app/controllers/rankings_controller.rb %}
class RankingsController < ApplicationController
  def index
    # fetch rankings from the old database
    @rankings = fetch_rankings
    # ...and lots more stuff; this was not a skinny controller
  end

  def show
    # fetch rankings from the old database for the given keyword
    @rankings = fetch_rankings_for_keyword(params[:keyword_id])
    # ...and lots more stuff; this was not a skinny controller
  end
end
{% endcodeblock %}

...and we changed it like so:

{% codeblock app/controllers/deprecated/legacy_rankings_controller.rb %}
module LegacyRankingsController
  def index
    # fetch rankings from the old database
    @rankings = fetch_rankings
    # ...and lots more stuff; this was not a skinny controller
  end

  def show
    # fetch rankings from the old database for the given keyword
    @rankings = fetch_rankings_for_keyword(params[:keyword_id])
    # ...and lots more stuff; this was not a skinny controller
  end
end
{% endcodeblock %}

{% codeblock app/controllers/rankings_controller.rb %}
require 'deprecated/legacy_rankings_controller'

class RankingsController < ApplicationController
  before_filter :conditionally_use_legacy_controller

  def index
    raise NotImplementedError, "The new code hasn't been written yet"
  end

  def show
    raise NotImplementedError, "The new code hasn't been written yet"
  end

private

  def conditionally_use_legacy_controller
    extend LegacyRankingsController unless current_user.using_silo?
  end
end
{% endcodeblock %}

Hopefully it's clear what's going on here, but in case it's not:

* Rails constructs a new instance of the controller class for every
  request.
* `extend` is standard ruby method that lets you apply a module to a
  single object instance. The methods in the module, like singleton
  methods, take precedence over the methods defined in the controller
  class.
* The before filter replaces the controller implementation
  with the logic in the module for all requests for users who
  are not yet using silo. The fact that rails uses a new instance of
  the controller for every request ensures that the module extension is
  performed (or not) for each request in isolation.

This gives us a very simple, clean way to route the requests to
different action implementations based on our feature flag.

## Step 4: Move the views into a deprecated directory

As with the models above, we moved the views from `app/views/rankings`
to `app/views/deprecated/rankings` to quarantine the old code. Of
course, this prevents rails from finding the views where it expects them...but luckily, rails
provides `prepend_view_paths` (both as an [instance
method](https://github.com/rails/rails/blob/v3.1.3/actionpack/lib/abstract_controller/view_paths.rb#L54-56)
and a [class
method](https://github.com/rails/rails/blob/v3.1.3/actionpack/lib/abstract_controller/view_paths.rb#L69-77)),
which solves this problem perfectly. We just need to tweak
`conditionally_use_legacy_controller` a bit to use the instance method:

{% codeblock app/controllers/rankings_controller.rb %}
def conditionally_use_legacy_controller
  unless current_user.using_silo?
    extend LegacyRankingsController
    prepend_view_path "app/views/deprecated"
  end
end
{% endcodeblock %}

This forces Rails to render the views in `app/views/rankings` for users on the new
rankings system, and to render the views in `app/views/deprecated/rankings` for users still on
the old system. It only affects this one request because we are using
the instance method `prepend_view_path`, not the class method.

## Wrapping Up

From here, I had a clean slate to implement the controller and views
for the new rankings system. The `using_silo` flag made it easy to let
admins try-out and test the new system before turning it on for all new
users. We migrated existing users over to the new system one-by-one, and
it was easy to get rid of the code for the old system once all users
were migrated.

I imagine this pattern would be useful in plenty of other situations,
too; it's a simple, clean way to route requests to different controller and
view implementations.
