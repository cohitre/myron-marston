# heroku-rails assumes the presence of Rails.root, so we'll define it here
module Rails
  def self.root
    @root ||= Pathname.new(File.expand_path('../..', __FILE__))
  end
end

# heroku-rails assumes these have already been required...
require 'yaml'
require 'active_support/core_ext/object/blank'

require 'heroku-rails'
require 'heroku/rails/tasks'
