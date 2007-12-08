#
# SIMPLE
#
TextFilters.define :simple, "Simple" do
  def render_text(text)
    text.gsub("\n", '<br/>')
  end
end
