require 'rake'
require 'ruby-debug'

namespace :blogspot do
  desc "Downloads the blogposts from my China blog into the _posts/china folder."
  task :download do
    mkdir_p '_posts'
    blogger_account = 'myronmarston'
    sh %Q(wget "http://#{blogger_account}.blogspot.com/feeds/posts/full?alt=rss&max-results=1000" -O "#{blogger_account}.rss.xml")
    sh %Q(ruby -r './lib/jekyll/converters/rss' -e 'Jekyll::RSS.process("'#{blogger_account}'.rss.xml")')
    rm "#{blogger_account}.rss.xml"
    mv '_posts', 'old_posts'
    mkdir_p '_posts'
    mv 'old_posts', '_posts/china'
  end
end
