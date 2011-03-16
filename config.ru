require "rubygems"
require "bundler/setup"
require 'rack'
require 'rack/contrib/try_static'
require 'rack/contrib/response_headers'
require 'refraction'

use Rack::ResponseHeaders do |headers|
  unless headers['Content-Type'] =~ /charset/
    headers['Content-Type'] << '; charset=utf8'
  end
end

Refraction.configure do |req|
  case req.path
  when %r|^/?$|; req.permanent! :path => '/n'
  when %r|^(/[^n].*)$|; req.permanent! :path => "/n#{$1}"
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

