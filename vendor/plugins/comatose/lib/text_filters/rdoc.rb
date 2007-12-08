#
# RDOC
#
TextFilters.define :rdoc, "RDoc" do
  require 'rdoc/markup/simple_markup'
  require 'rdoc/markup/simple_markup/to_html'

  def render_text(text)
    p = SM::SimpleMarkup.new
    h = SM::ToHtml.new
    p.convert(text, h)  
  end
end
