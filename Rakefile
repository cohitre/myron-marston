require 'rake'
require './tasks/heroku.rb'
require './tasks/china_blog.rb'

desc "Compiles the china blog posts"
task :compile do
  sh "bundle exec jekyll"
end

desc "Runs the site"
task :run do
  sh "bundle exec rackup config.ru"
end
