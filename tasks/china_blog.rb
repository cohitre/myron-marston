namespace :china_blog do
  blogger_account = 'myronmarston'

  desc "Downloads the blogposts from my China blog into the _posts/china folder."
  task :download do
    rm_rf 'static/china/_posts'
    mkdir_p 'static/china/_posts'
    sh %Q(wget "http://#{blogger_account}.blogspot.com/feeds/posts/full?alt=rss&max-results=1000" -O "#{blogger_account}.rss.xml")
    sh %Q(ruby -r './lib/jekyll/converters/rss' -e 'Jekyll::RSS.process("'#{blogger_account}'.rss.xml")')
    rm "#{blogger_account}.rss.xml"
  end

  desc "Fix the china blog post links so they point to the local posts."
  task :fix_links do
    require './lib/blogspot_importer'
    BlogspotImporter.fix_links
  end

  desc "Generates a URL map for disqus"
  task :generate_url_map do
    require './lib/blogspot_importer'
    require 'nokogiri'
    sh %Q(wget "http://#{blogger_account}.blogspot.com/feeds/posts/full?alt=rss&max-results=1000" -O "#{blogger_account}.rss.xml")

    content = File.read("#{blogger_account}.rss.xml")
    doc = Nokogiri::XML(content)

    File.open('./disqus_china_url_map.csv', 'w') do |url_map|
      doc.xpath("/rss/channel/item").each do |item|
        old_url = item.css("link").text
        new_url = BlogspotImporter.new_url_for(old_url)

        url_map.puts "#{old_url}, http://myronmars.to#{new_url}"
      end
    end

    rm "#{blogger_account}.rss.xml"
  end
end

desc "Re-import china blog from scratch"
task :china_blog => ['china_blog:download', 'china_blog:fix_links', 'china_blog:generate_url_map', 'compile']
