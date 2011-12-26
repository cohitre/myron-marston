require 'digest/md5'

module CacheBustFilter
  def self.source_dir
    @source_dir ||= Jekyll.configuration({})['source']
  end

  def cache_bust(input)
    file = File.join(CacheBustFilter.source_dir, input)
    md5 = Digest::MD5.hexdigest(File.read(file))
    "#{input}?#{md5}"
  end
end

Liquid::Template.register_filter(CacheBustFilter)
