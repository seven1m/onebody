#
# MARKDOWN
#
TextFilters.define :markdown, "Markdown" do
  require 'bluecloth'
  
  def render_text(text)
    BlueCloth.new(text).to_html
  end
  
  def create_link(title, url)
    "[#{title}](#{url})"
  end
end
