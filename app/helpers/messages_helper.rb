module MessagesHelper
  include ERB::Util

  def get_email_body(msg)
    if (alternative = msg.parts.detect { |p| p.content_type.downcase.split(';').first == 'multipart/alternative' }) &&
        (plain = alternative.parts.detect { |p| p.content_type.downcase.split(';').first == 'text/plain' })
      plain.body
    elsif plain = msg.parts.detect { |p| p.content_type.downcase.split(';').first == 'text/plain' }
      plain.body
    else
      msg.body
    end
  end

  def render_message_body(message)
    if message.is_a?(StreamItem)
      if message.text?
        render_message_text_body(message.body)
      else
        render_message_html_body(message.body)
      end
    elsif message.html_body.present?
      render_message_html_body(message.html_body)
    else
      render_message_text_body(message.body)
    end
  end

  def render_message_html_body(message_body)
    html = sanitize_html(remove_sensitive_links(auto_link(message_body, sanitize: false))).html_safe
    html.gsub!(/(\-\s){20,}.{0,15}Hit "Reply".+$/m, '')
    html.gsub!(/<blockquote>(\s*[^\s]+.+\s*)<\/blockquote>/mi, "<div class=\"quoted-content\"><div style=\"display:none;\">\\1</div><a href=\"#\" onclick=\"$(this).hide().prev().show();return false;\">#{I18n.t('messages.show_quoted_content')}</a></div>")
    html.gsub!(/<p><p>[^:graph:]*<\/p><\/p>/, '<br/>') # paragraphs inside paragraphs? C'mon Microsoft!
    html.gsub!(/(<br\s?\/?>\s*){3,}/mi, '<br/><br/>')
    html.html_safe
  end

  def render_message_text_body(message_body)
    body = h(remove_sensitive_links(message_body))
    body = auto_link(preserve_breaks(remove_excess_breaks(body), false))
    body.gsub!(/(<br\s?\/?>&gt;.*){3,}/mi, "<div class=\"quoted-content\"><div style=\"display:none;\">\\0</div><a href=\"#\" onclick=\"$(this).hide().prev().show();return false;\">#{I18n.t('messages.show_quoted_content')}</a></div>")
    body.html_safe
  end

  def remove_sensitive_links(message_body)
    # To stop email from this group:
    # http://crccfamily.com/groups/364/memberships/25978?code=69V5ZB65iidcs3lUrgdTADX74MqOHuz2UNeVeRSb8w8r3YvZsj&amp;email=off
    message_body.gsub(%r{https?://[^/]+/groups/\d+/memberships/\d+\?code=[^\s]+}, '')
  end
end
