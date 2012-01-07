---
layout: dev_post
title: Why Sinatra's Halt is Awesome
section: dev-blog
contents_class: medium-wide
---

Most of Sinatra's well-deserved praise is directed toward its
simple, elegant routing DSL. I want to talk a bit about another
feature that I love that doesn't get much attention: Sinatra's `halt`.

One of the biggest sources of complexity when developing robust
applications is all of the error-handling code. Generally, code
is easier to understand and more maintainable when the error handling
is not mixed together with the "happy path" code. This is one reason
that virtually all modern languages have opted to provide exceptions
rather than old C-style error return values. `halt` provides similar
benefits.

Consider a simple sinatra route:

{% codeblock application.rb %}
get '/users/:user_id/projects/:project_id/tasks-due-on/:task_date' do
  user = User.find(params[:user_id])
  project = user.projects.find(params[:project_id])
  tasks = project.tasks_due_on(Date.parse(params[:task_date]))
  tasks.to_json
end
{% endcodeblock %}

This is all "happy path" code, and there are a few potential problems
that aren't handled at all:

* The user record for the given `:user_id` may not exist.
* The project record for the given `:project_id` may not exist,
   or may not belong to the given user.
* The `:task_date` date string may not be in iso8601 format
  (i.e. YYYY-MM-DD).

Let's handle each of these so that our API returns
semantic HTTP status codes rather than responding with a 500 error:

{% codeblock application.rb %}
get '/users/:user_id/projects/:project_id/tasks-due-on/:task_date' do
  user = User.find(params[:user_id])

  if user
    project = user.projects.find(params[:project_id])

    if project 
      begin
        tasks = project.tasks_due_on(Date.iso8601(params[:task_date]))
      rescue ArgumentError # for an invalid date string
        status 400 # bad request
      else
        tasks.to_json
      end
    else
      status 404 # not found
    end
  else
    status 404 # not found
  end
end
{% endcodeblock %}

This is certainly more robust, but I really, really hate this style of code.
Let's clean it up a bit with some helper methods:

{% codeblock application.rb %}
helpers do
  def user
    @user ||= User.find(params[:user_id]).tap do |user|
      halt 404 unless user
    end
  end

  def project
    @project ||= user.projects.find(params[:project_id]).tap do |project|
      halt 404 unless project
    end
  end

  def task_date
    @task_date ||= Date.iso8601(params[:task_date])
  rescue ArgumentError
    halt 400
  end

  def tasks
    @tasks ||= project.tasks_due_on(task_date)
  end
end

get '/users/:user_id/projects/:project_id/tasks-due-on/:task_date' do
  tasks.to_json
end
{% endcodeblock %}

Much, much better. It's more lines of code, but so much simpler.
The error handling for each piece of data is handled
directly in the helper method that is responsible for that piece of
data. This has the added benefit of making it simpler to implement
other routes that need some of these pieces of data:

{% codeblock application.rb %}
helpers do
  # all the helpers defined above...
end

get '/users/:user_id/projects/:project_id' do
  project.to_json
end

get '/users/:user_id/projects/:project_id/tasks-due-on/:task_date' do
  tasks.to_json
end
{% endcodeblock %}

This is only possible through the magic of `halt`. Under the covers,
`halt` uses `throw`[^foot_1] to immediately stop processing the route
and return the response given to `halt`. Some ruby developers have
[gone on record as hating ruby's
throw](http://m.onkey.org/ruby-i-don-t-like-2-catch-wtf-throw-wtf), and
it can certainly be abused...but Sinatra's `halt` sure is useful and
is only made possible by `throw`[^foot_2].

[^foot_1]: If you're unfamiliar with `throw`, check out Avdi Grimm's [blog
  post](http://rubylearning.com/blog/2011/07/12/throw-catch-raise-rescue-im-so-confused/)
  on the topic.
[^foot_2]: Technically, you could implement `halt` using exceptions, but
  that seems semantically wrong to me. `throw` is specifically intended
  for cases like these.

