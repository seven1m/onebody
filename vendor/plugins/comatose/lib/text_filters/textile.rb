#
# TEXTILE
#
TextFilters.define :textile, "Textile" do
  require 'redcloth'
  
  def render_text(text)
    RedCloth.new(text).to_html(:refs_markdown, :textile, :markdown)
  end
  
  def create_link(title, url)
    %Q|"#{title}":#{url}|
  end
  
end
