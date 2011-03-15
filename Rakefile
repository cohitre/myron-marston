require 'rake'
require './tasks/heroku.rb'
require './tasks/china_blog.rb'

desc "Compiles the china blog posts"
task :compile do
  sh "bundle exec jekyll"
end

desc "Starts jekyll so that it watches changes and recompiles the site."
task :watch do
  sh "bundle exec jekyll --auto"
end

desc "Runs the site"
task :run do
  sh "bundle exec rackup config.ru"
end
