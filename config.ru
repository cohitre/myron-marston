require "rubygems"
require "bundler/setup"
require 'rack'
require 'rack/contrib/try_static'
require 'rack/contrib/response_headers'
require 'refraction'

use Rack::ResponseHeaders do |headers|
  if headers['Content-Type'] =~ %r|text/html|
    # cache for 5 minutes
    headers['Cache-Control'] = 'public, max-age=300'
  end

  unless headers['Content-Type'] =~ /charset/
    headers['Content-Type'] << '; charset=utf-8'
  end
end

Refraction.configure do |req|
  case req.path
  when %r|^/?$|; req.permanent! :path => '/n'
  when %r|^(/[^n].*)$|; req.permanent! :path => "/n#{$1}"
  when %r|^(.*)\.html$|; req.permanent! :path => $1
  when %r|^(.*)/index(\.html)?$|; req.permanent! :path => $1
  when %r|^/n/?$|; req.permanent! :path => '/n/dev-blog'
  when %r|^/n/atom.xml$|
    if %w[ FeedBurner FeedValidator ].none? { |u| req.env['HTTP_USER_AGENT'].to_s.include?(u) }
      req.permanent! "http://feeds.feedburner.com/myronmarsto/n"
    end
  end
end

use Refraction

use Rack::TryStatic,
    :root => "static/_site",  # static files root dir
    :urls => %w[/],     # match all requests
    :try => ['.html', 'index.html', '/index.html'] # try these postfixes sequentially

# Like https://github.com/rack/rack-contrib/blob/31370b78d75faa6609ffb2e15dbc2aa7edd0422d/lib/rack/contrib/not_found.rb,
# but uses bytesize so we can pass Rack::Lint
module Rack
  # Rack::NotFound is a default endpoint. Initialize with the path to
  # your 404 page.

  class NotFound
    F = ::File

    def initialize(path)
      file = F.expand_path(path)
      @content = F.read(file)
      @length = @content.bytesize.to_s
    end

    def call(env)
      [404, {'Content-Type' => 'text/html', 'Content-Length' => @length}, [@content]]
    end
  end
end

# otherwise 404 NotFound
run Rack::NotFound.new("static/_site/n/not_found.html")

