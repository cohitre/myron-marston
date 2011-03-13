require "rubygems"
require "bundler/setup"
require 'rack'
require 'rack/contrib/try_static'
require 'rack/contrib/response_headers'

use Rack::ResponseHeaders do |headers|
  unless headers['Content-Type'] =~ /charset/
    headers['Content-Type'] << '; charset=utf8'
  end
end

use Rack::TryStatic,
    :root => "static/_site",  # static files root dir
    :urls => %w[/],     # match all requests
    :try => ['.html', 'index.html', '/index.html'] # try these postfixes sequentially

# otherwise 404 NotFound
run lambda { |env| [404, {'Content-Type' => 'text/html'}, ['whoops! Not Found']]}

