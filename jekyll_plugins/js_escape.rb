require 'ruby-debug'
module JSEscape
  def js_escape(input)
    input.gsub("'") { "\\'" }
  end
end

Liquid::Template.register_filter(JSEscape)
