require 'pathname'

# heroku-rails assumes the presence of Rails.root, so we'll define it here
module Rails
  def self.root
    @root ||= Pathname.new(File.expand_path('../..', __FILE__))
  end
end

# heroku-rails assumes these have already been required...
require 'yaml'

begin
  require 'active_support/core_ext/object/blank'
  require 'heroku-rails'
  require 'heroku/rails/tasks'
rescue LoadError
  puts "Could not load heroku-rails tasks"
end

namespace :db do
  task :migrate do
    # No-op: this is just hear because heroku-rails runs db:migrate on
    # each deploy, and we don't want to get an error because of a
    # missing task.
  end
end
