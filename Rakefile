require 'rake'
require './tasks/heroku.rb'
require './tasks/china_blog.rb'

desc "Compiles the china blog posts"
task :compile do
  sh "bundle exec jekyll"
end

namespace :watch do
  desc "Starts jekyll so that it watches changes and recompiles the site."
  task :jekyll do
    sh "bundle exec jekyll --auto"
  end

  desc "Starts compass so that it watches changes to the sass and recompiles it"
  task :compass do
    sh "bundle exec compass watch"
  end
end

desc "Runs the site"
task :run do
  sh "bundle exec rackup config.ru"
end

desc "Deploys the site"
task :deploy do
  sh "git push production master"
end
