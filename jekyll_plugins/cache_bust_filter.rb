module CacheBustFilter
  def self.source_dir
    @source_dir ||= Jekyll.configuration({})['source']
  end

  def cache_bust(input)
    file = File.join(CacheBustFilter.source_dir, input)
    asset_id = File.mtime(file).to_i.to_s
    "#{input}?#{asset_id}"
  end
end

Liquid::Template.register_filter(CacheBustFilter)
