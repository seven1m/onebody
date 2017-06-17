module MapsHelper
  def map_header(object)
    return unless object.mapable?
    content_for(:header) do
      content_tag(:div, '', id: 'map', data: map_data(object)) +
        content_tag(:section, class: 'content-header map-overlay') do
          breadcrumbs +
            content_tag(:h1) do
              (@title + map_sub_title).html_safe
            end
        end
    end
  end

  def map_sub_title
    sub_title = content_for(:sub_title)
    return '' unless sub_title
    content_tag(:small, sub_title)
  end

  def map_data(object)
    {
      latitude: object.latitude,
      longitude: object.longitude,
      address: preserve_breaks(object.pretty_address),
      notice: t('maps.notice'),
      zoom: Setting.get(:system, :map_zoom_level)
    }
  end

  def directory_map_div
    content_tag(:div, '', id: 'directory_map', data: directory_map_data)
  end

  def directory_map_data
    {
      notice: t('maps.notice')
    }
  end

  def directory_map_header
    content_for(:header) do
      content_tag(:section, class: 'content-header') do
        breadcrumbs +
          content_tag(:h1) do
            'Directory Map'
          end
      end
    end
  end
end
