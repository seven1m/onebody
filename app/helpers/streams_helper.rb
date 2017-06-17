module StreamsHelper
  include MessagesHelper

  def stream_item_url(stream_item)
    if stream_item.streamable_type == 'Site'
      root_url
    else
      send(stream_item.streamable_type.underscore + '_url', stream_item.streamable_id)
    end
  end

  # TODO: remove this, but fix show.xml.builder first
  def stream_item_content(stream_item, use_code = false)
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
    if use_code && content
      content.gsub!(/<img([^>]+)src="(.+?)"/) do |_match|
        url = Regexp.last_match(2) && (Regexp.last_match(2) + (Regexp.last_match(2).include?('?') ? '&' : '?') + 'code=' + @logged_in.feed_code)
        "<img#{Regexp.last_match(1)}src=\"#{url}\""
      end
    end
    content.try(:html_safe)
  end

  def new_stream_activity(person)
    StreamItem.shared_with(person)
              .where('stream_items.created_at > ?', person.last_seen_stream_item.try(:created_at) || Time.now)
              .count('distinct stream_items.id')
  end
end
