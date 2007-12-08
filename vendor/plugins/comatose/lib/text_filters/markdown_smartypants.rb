#
# MARKDOWN + SMARTYPANTS
#
TextFilters.define :markdown_smartypants, "Markdown + SmartyPants" do
  require 'bluecloth'
  require 'rubypants'
  
  def render_text(text)
    RubyPants.new( BlueCloth.new(text).to_html ).to_html
  end
  
  def create_link(title, url)
    "[#{title}](#{url})"
  end
end
