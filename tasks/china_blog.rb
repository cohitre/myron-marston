namespace :china_blog do
  desc "Downloads the blogposts from my China blog into the _posts/china folder."
  task :download do
    mkdir_p '_posts'
    blogger_account = 'myronmarston'
    sh %Q(wget "http://#{blogger_account}.blogspot.com/feeds/posts/full?alt=rss&max-results=1000" -O "#{blogger_account}.rss.xml")
    sh %Q(ruby -r './lib/jekyll/converters/rss' -e 'Jekyll::RSS.process("'#{blogger_account}'.rss.xml")')
    rm "#{blogger_account}.rss.xml"
    mkdir_p 'static/china'
    mv '_posts', 'static/china/_posts'
  end

  desc "Fix the china blog post links so they point to the local posts."
  task :fix_links => :download do
    require './lib/blogspot_importer'
    BlogspotImporter.fix_links
  end
end

