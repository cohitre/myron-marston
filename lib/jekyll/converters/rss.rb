require 'time'
require "yaml"
require 'nokogiri'
require 'ruby-debug'
require 'psych'

module Jekyll

  module RSS
    #Reads posts from an RSS feed.
    #It creates a post file for each entry in the RSS.
    def self.process(source = "rss.xml")
      content = File.read(source)
      doc = Nokogiri::XML(content)
      posts = 0
      doc.xpath("/rss/channel/item").each do |item|
        link = item.css("link").text

        # Use the URL after the last slash as the post's name
        name = link.split("/")[-1]
        
        # Remove html extension
        name.gsub!(/\.html$/, '')

        title = item.css("title").text

        content_element = item.css('description')
        unless content_element
          puts "No content in RSS item '#{name}'\n"
          next
        end
        content = content_element.text
        timestamp = Time.parse(item.css("pubDate").text).utc
        filename = "static/china/_posts/#{timestamp.strftime("%Y-%m-%d")}-#{name}.html"
        puts "#{link} -> #{filename}"
        File.open(filename, "w") do |f|
          Psych.dump(
            {
              "layout" => "china_post",
              "name" => name,
              "title" => title.gsub('&', '&amp;'),
              "time" => timestamp,
            },
            f
          )
          f.puts "---\n#{content}"
        end
        posts += 1
      end
      puts "Created #{posts} posts!"
    end
  end
end
