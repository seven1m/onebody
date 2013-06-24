module StreamsHelper
  include MessagesHelper

  def stream_item_path(stream_item)
    send(stream_item.streamable_type.underscore + '_path', stream_item.streamable_id)
  end

  def stream_item_url(stream_item)
    send(stream_item.streamable_type.underscore + '_url', stream_item.streamable_id)
  end

  def stream_item_content(stream_item, use_code=false)
    if stream_item.body
      content = if stream_item.streamable_type == 'Message'
        render_message_body(stream_item)
      else
        sanitize_html(auto_link(stream_item.body))
      end
    elsif stream_item.context.any?
      content = ''.tap do |content|
        stream_item.context['picture_ids'].to_a.each do |picture_id, fingerprint, extension|
          content << link_to(
            image_tag(Picture.photo_url_from_parts(picture_id, fingerprint, extension, :small), alt: t('pictures.click_to_enlarge'), class: 'stream-pic'),
            album_picture_path(stream_item.streamable_id, picture_id), title: t('pictures.click_to_enlarge')
          ) + ' '
        end
      end
    end
    if use_code
      content.gsub!(/<img([^>]+)src="(.+?)"/) do |match|
        url = $2 && ($2 + ($2.include?('?') ? '&' : '?') + 'code=' + @logged_in.feed_code)
        "<img#{$1}src=\"#{url}\""
      end
    end
    content.html_safe
  end

  def recent_time_ago_in_words(time)
    if time >= 1.day.ago
      time_ago_in_words(time) + ' ' + t('stream.ago')
    else
      time.to_s
    end
  end

end
