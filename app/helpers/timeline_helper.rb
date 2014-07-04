module TimelineHelper
  def timeline(stream_items)
    last_date = nil
    if stream_items.any?
      types = []
      content_tag(:ul, class: 'timeline', 'data-next-url' => next_timeline_url) do
        [].tap do |items|
          @stream_items.each_with_index do |stream_item, index|
            next unless stream_item.decorate.publishable?
            next if skip_duplicate_streamable_type?(types, stream_item.streamable_type)
            types << stream_item.streamable_type
            if stream_item.created_at != last_date
              items << timeline_date_label(stream_item)
              last_date = stream_item.created_at
            end
            items << stream_item.decorate.to_html(first: index == 0)
          end
        end.join.html_safe
      end.html_safe +
      (timeline_has_more?(stream_items) ? timeline_load_more : '')
    end
  end

  def timeline_none(label=t('stream.none'))
    content_tag(:div, label, class: 'timeline-none')
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

  def timeline_has_more?(stream_items)
    (stream_items.total_entries / stream_items.per_page.to_f) > stream_items.current_page
  end

  def timeline_load_more
    content_tag(:div, class: 'timeline-load-more') do
      link_to(I18n.t('stream.load_more'), "?timeline_page=#{timeline_page+1}", class: 'btn btn-primary btn-xs')
    end +
    content_tag(:div, '', class: 'clearfix')
  end

  def timeline_page
    (params[:timeline_page] || 1).to_i
  end

  def next_timeline_url(page=nil)
    page = timeline_page + 1
    if params[:controller] == 'people' or params[:person_id]
      person_stream_url(@person || params[:person_id], format: :json, timeline_page: page)
    elsif params[:controller] == 'groups' or params[:group_id]
      group_stream_url(@group || params[:group_id], format: :json, timeline_page: page)
    else
      stream_url(format: :json, timeline_page: page)
    end
  end

  MAX_RUNS = {
    person: 2
  }

  def skip_duplicate_streamable_type?(types, next_type)
    if max = MAX_RUNS[next_type.downcase.to_sym]
      return true if types.length >= max and types[-max..-1].all? { |p| p == next_type }
    end
  end
end
