require 'tempfile'

module BlogspotImporter
  extend self

  def markdown_from(html)
    tempfile = Tempfile.new('html')
    tempfile.write(html)
    tempfile.close
    `cat #{tempfile.path} | tidyp -f /tmp/tidyp_errors.txt | ./html2text.py`.tap do |m|
      tempfile.unlink
    end
  end

  def parse_post(filename)
    post_regex = /(\A-{3}.+-{3})(.+)\z/m # http://rubular.com/r/5ndrWRXgEt
    File.read(filename).match(post_regex).captures
  end

  def convert_to_markdown
    Dir.new('static/china/_posts').entries.each do |filename|
      next unless filename =~ /\.html$/
      filename = "static/china/_posts/#{filename}"

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
end
