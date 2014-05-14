module TimelineHelper
  def timeline(stream_items)
    last_date = nil
    content_tag(:ul, class: 'timeline', 'data-next-url' => next_timeline_url) do
      @stream_items.flat_map do |stream_item|
        items = []
        if stream_item.created_at != last_date
          items << timeline_date_label(stream_item)
          last_date = stream_item.created_at
        end
        items << stream_item.decorate.to_html
      end.join.html_safe
    end.html_safe +
    content_tag(:div, class: 'timeline-load-more') do
      link_to(I18n.t('stream.load_more'), '#', class: 'btn btn-primary btn-xs')
    end
  end

  def timeline_date_label(stream_item)
    date = stream_item.created_at.to_s(:date)
    if date != @last_date
      @last_date = date
      content_tag(:li, class: 'time-label') do
        content_tag(:span, class: 'bg-green') do
          stream_item.created_at.to_s(:date)
        end
      end
    end
  end

  def next_timeline_url(page=nil)
    page ||= (params[:page] || 1).to_i + 1
    if params[:controller] == 'people' or params[:person_id]
      person_stream_url(@person || params[:person_id], format: :json, page: page)
    else
      stream_url(format: :json, page: page)
    end
  end
end
