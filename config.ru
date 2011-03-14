require "rubygems"
require "bundler/setup"
require 'rack'
require 'rack/contrib/try_static'
require 'rack/contrib/response_headers'
require 'refraction'

if ENV['RACK_ENV'] == 'development'
  require 'ruby-debug'
  class JekyllReloader
    def initialize(app)
      @app = app
    end

    def reload!
      if @reload_pid
        Process.wait(@reload_pid)
        @reload_pid = nil
      else
        @reload_pid = fork do
          puts "Recompiling site..."
          `jekyll`
          puts "...done."
        end
      end
    end

    def asset?(env)
      env['PATH_INFO'] =~ /\.(js|css|ico|png|jpg|jpeg|gif)$/
    end

    def call(env)
      reload! unless asset?(env)
      @app.call(env)
    end
  end

  use JekyllReloader
end

use Rack::ResponseHeaders do |headers|
  unless headers['Content-Type'] =~ /charset/
    headers['Content-Type'] << '; charset=utf8'
  end
end

Refraction.configure do |req|
  case req.path
  when %r|^(.*)\.html$|; req.permanent! :path => $1
  when %r|^(.*)/index(\.html)?$|; req.permanent! :path => $1
  end
end

use Refraction

use Rack::TryStatic,
    :root => "static/_site",  # static files root dir
    :urls => %w[/],     # match all requests
    :try => ['.html', 'index.html', '/index.html'] # try these postfixes sequentially

# otherwise 404 NotFound
run lambda { |env| [404, {'Content-Type' => 'text/html'}, ['whoops! Not Found']]}

