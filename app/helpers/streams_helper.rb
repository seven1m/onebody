module StreamsHelper
  
  def stream_icon(stream_item)
    src = case stream_item.streamable_type
    when 'NewsItem'
      'newspaper.png'
    when 'Note'
      'note.png'
    when 'Verse'
      'verse.png'
    when 'Album'
      'picture.png'
    when 'Publication'
      'page.png'
    else
      return nil
    end
    image_tag(src, :alt => stream_item.title, :class => 'icon')
  end
  
  def stream_item_path(stream_item)
    send(stream_item.streamable_type.underscore + '_path', stream_item.streamable_id)
  end
  
  def recent_time_ago_in_words(time)
    if time >= 1.day.ago
      time_ago_in_words(time) + ' ago'
    else
      time.to_s
    end
  end
  
  def stream_type_checkmark(name, type, checked_by_default=true)
    enabled = cookies["stream_#{type}"]
    enabled = cookies["stream_#{type}"] = checked_by_default if cookies["stream_#{type}"].nil?
    link_to_function(
      image_tag(enabled ? 'checkmark.png' : 'remove.gif', :alt => "Enable/Disable #{name}", :class => 'icon') + " #{name}",
      "enable_stream_item_type('" + type + "', this.getElementsByTagName('img')[0].readAttribute('src') != '/images/checkmark.png');",
      :id => "enable-stream_" + type
    )
  end
  
end
