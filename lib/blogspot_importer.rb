require 'tempfile'
require 'amatch'
require 'date'

module BlogspotImporter
  extend self

  def posts_dir
    @posts_dir ||= Dir.new('static/china/_posts')
  end

  def post_files
    @post_file ||= posts_dir.entries.select { |e| e =~ /md/ }
  end

  def markdown_from(html)
    tempfile = Tempfile.new('html')
    tempfile.write(html)
    tempfile.close
    `cat #{tempfile.path} | tidy -utf8 | ./html2text.py`.tap do |m|
      tempfile.unlink
    end
  end

  def parse_post(filename)
    post_regex = /(\A-{3}.+-{3})(.+)\z/m # http://rubular.com/r/5ndrWRXgEt
    File.read(filename).match(post_regex).captures
  end

  def convert_to_markdown
    posts_dir.entries.each do |filename|
      next unless filename =~ /\.html$/
      filename = "#{posts_dir.path}/#{filename}"

      yaml_front_matter, html_content = parse_post(filename)
      markdown = markdown_from(html_content)

      File.open(filename.sub(/\.html$/, '.md'), 'w') do |file|
        file.write(yaml_front_matter)
        file.puts
        file.write(markdown)
      end

      FileUtils.rm filename

      puts "Converted #{filename} to markdown"
    end
  end

  # http://rubular.com/r/VbzKn5lbgA
  LINK_REGEX = /(^   \[\d+\]: )https?:\/\/myronmarston.blogspot.com\/(\d{4})\/(\d{2})\/([\w\-]+)(?:\.html)?(\s*$)/

  def fix_links
    post_files.each do |filename|
      filename = "#{posts_dir.path}/#{filename}"

      content = File.read(filename)
      content.gsub!(LINK_REGEX) do |match|
        whole_match, prefix, year, month, fragment, suffix = $&, $1, $2, $3, $4, $5
        path = whole_match[/\d{4}.*$/]
        blogspot_month_date = Date.civil(year.to_i, month.to_i, 1)

        nearby_posts = post_files.select do |p|
          post_date = Date.parse(p)
          (post_date - blogspot_month_date).to_i.abs < 60
        end

        fragment = fragment.sub(/my-winter-travels-part-\d+-/, '')
        pattern = Amatch::Levenshtein.new(fragment)
        best_match = nearby_posts.sort { |a, b| pattern.match(a) <=> pattern.match(b) }.first

        best_match_path = best_match.sub(/^(\d{4})\-(\d{2})\-(\d{2})\-([\w\-]+)\.md$/, '/\1/\2/\3/\4')
        puts "Replacing #{path} with #{best_match_path}"
        prefix + best_match_path + suffix
      end

      File.open(filename, 'w') { |f| f.write(content) }
    end
  end
end
