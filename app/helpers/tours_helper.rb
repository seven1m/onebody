module ToursHelper

  def tour_popup(name, url, width, align)
    html = ''
    html << stylesheet_link_tag('modalbox.css')
    html << javascript_include_tag('modalbox.js')
    html << '<script type="text/javascript">'
    html << "Modalbox.show('#{url}', {title: 'Site Tour - #{name}', width: #{width}, align: '#{align}'});"
    html << "Modalbox.resizeToContent();"
    html << '</script>'
  end

end
