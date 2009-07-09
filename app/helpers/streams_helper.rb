module StreamsHelper
  
  def stream_icon(stream_item)
    src = case stream_item.streamable_type
    when 'NewsItem'
      'newspaper.png'
    else
      return nil
    end
    image_tag(src, :alt => stream_item.title, :class => 'icon')
  end
  
end
