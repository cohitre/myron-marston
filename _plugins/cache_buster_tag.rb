module Jekyll
  class CacheBusterTag < Liquid::Tag
    def render(context)
      Time.now.to_i.to_s
    end
  end
end

Liquid::Template.register_tag('cache_buster', Jekyll::CacheBusterTag)

