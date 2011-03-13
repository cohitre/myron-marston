require 'date'
require 'nokogiri'

module BlogspotImporter
  extend self

  def posts_dir
    @posts_dir ||= Dir.new('static/china/_posts')
  end

  def post_files
    @post_file ||= posts_dir.entries.select { |e| e =~ /html/ }
  end

  def parse_post(filename)
    post_regex = /(\A-{3}.+-{3})(.+)\z/m # http://rubular.com/r/5ndrWRXgEt
    File.read(filename).match(post_regex).captures
  end

  def fix_post_links(html)
    doc = Nokogiri::HTML::DocumentFragment.parse(html)

    doc.search('a').each do |link|
      href = link.attribute('href')
      next unless href.value =~ %r|myronmarston\.blogspot\.com/\d{4}/\d{2}/([\w\-]+)(?:\.html)$|
      slug = $1
      matching_files = post_files.select { |f| f.end_with?(slug + '.html') }

      unless matching_files.size == 1
        puts
        puts "Could not find a single file for slug '#{slug}': #{matching_files.inspect}"
        puts
        next
      end

      file = matching_files.first
      year, month, day = file.match(/(\d{4})-(\d{2})-(\d{2})/).captures
      new_href = "/china/#{year}/#{month}/#{day}/#{slug}"

      puts "replacing #{href.value} with #{new_href}"
      href.value = new_href
    end

    doc.to_html
  end

  def fix_links
    post_files.each do |filename|
      filename = "#{posts_dir.path}/#{filename}"

      yaml_front_matter, html_content = parse_post(filename)
      fixed_html = fix_post_links(html_content)

      File.open(filename, 'w') do |file|
        file.write(yaml_front_matter)
        file.write(fixed_html)
      end
    end
  end
end
