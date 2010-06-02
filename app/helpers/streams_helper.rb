module StreamsHelper
  include MessagesHelper

  def stream_icon(stream_item)
    src = case stream_item.streamable_type
    when 'NewsItem'
      'newspaper.png'
    when 'Note'
      'note.png'
    when 'Message'
      if stream_item.wall_id
        'comments.png'
      else
        'message.gif'
      end
    when 'Verse'
      'verse.png'
    when 'Album'
      'picture.png'
    when 'Publication'
      'page.png'
    when 'Recipe'
      'recipe.png'
    when 'PrayerRequest'
      'heart.png'
    else
      return nil
    end
    image_tag(src, :alt => stream_item.title, :class => 'icon')
  end

  def stream_item_path(stream_item)
    send(stream_item.streamable_type.underscore + '_path', stream_item.streamable_id)
  end

  def stream_item_url(stream_item)
    send(stream_item.streamable_type.underscore + '_url', stream_item.streamable_id)
  end

  def stream_item_content(stream_item, use_code=false)
    if stream_item.body
      if stream_item.streamable_type == 'Message'
        content = render_message_html_body(stream_item.body)
      else
        content = white_list_with_removal(auto_link(stream_item.body))
      end
    elsif stream_item.context.any?
      content = ''
      stream_item.context['picture_ids'].to_a.each do |picture_id|
        content << link_to(
          image_tag(small_album_picture_photo_path(stream_item.streamable_id, picture_id), :alt => I18n.t('pictures.click_to_enlarge'), :class => 'stream-pic'),
          album_picture_path(stream_item.streamable_id, picture_id), :title => I18n.t('pictures.click_to_enlarge')
        ) + ' '
      end
    end
    if use_code
      content.gsub!(/<img([^>]+)src="(.+?)"/) do |match|
        url = $2 + ($2.include?('?') ? '&' : '?') + 'code=' + @logged_in.feed_code
        "<img#{$1}src=\"#{url}\""
      end
    end
    content
  end

  def recent_time_ago_in_words(time)
    if time >= 1.day.ago
      time_ago_in_words(time) + ' ' + I18n.t('stream.ago')
    else
      time.to_s
    end
  end

  def stream_type_checkmark(name, type, checked_by_default=true)
    enabled = cookies["stream_#{type}"]
    enabled = cookies["stream_#{type}"] = checked_by_default if cookies["stream_#{type}"].nil?
    link_to_function(
      image_tag(enabled ? 'checkmark.png' : 'remove.gif', :alt => I18n.t('stream.enable_disable') + " #{name}", :class => 'icon') + " #{name}",
      "enable_stream_item_type('" + type + "', this.getElementsByTagName('img')[0].readAttribute('src') != '/images/checkmark.png');",
      :id => "enable-stream_" + type
    )
  end


end
