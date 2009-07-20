module ToursHelper

  def tour_popup(name, page_name, width, align)
    html = ''
    html << stylesheet_link_tag('modalbox.css')
    html << javascript_include_tag('modalbox.js')
    html << '<script type="text/javascript">'
    html << "Modalbox.show(#{Page.find_by_title(page_name).body.inspect}, {title: 'Site Tour - #{name}', width: #{width}, align: '#{align}'});"
    html << '</script>'
  end

end
