module ToursHelper

  def tour_popup(name, url, width, align)
    if File.exist?("#{Rails.root}/public/#{url.sub(/^\/pages\//, '')}.#{I18n.locale}.html.liquid")
      html = ''
      html << stylesheet_link_tag('modalbox.css')
      html << javascript_include_tag('modalbox.js')
      html << '<script type="text/javascript">'
      html << "Modalbox.show('#{url}', {title: 'Site Tour - #{name}', width: #{width}, align: '#{align}'});"
      html << "setTimeout('Modalbox.resizeToContent()', 5000);" # hack to fit content
      html << '</script>'
    end
  end

end
