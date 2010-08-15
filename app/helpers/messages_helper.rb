module MessagesHelper
  def remove_bulk_quoting(message_body)
    message_body = message_body.strip.split(/[\-_]{10,}\n([^\n]+\n?)?http:\/\/[^\n]+/).first
    trimmed = []
    bulk = true
    message_body.strip.split(/\n/).reverse.each do |line|
      unless (line.strip.empty? or line =~ /^>/) and bulk
        trimmed << line
        bulk = false
      end
    end
    trimmed.reverse.join("\n").split(/\s*[\-_]+?.original.message.[\-_]+?/i).first.split(/[\-_]+\s*from:.*?\(via/i).first.strip
  end

  def get_email_body(msg)
    if alternative = msg.parts.detect { |p| p.content_type.downcase == 'multipart/alternative' } and
      plain = alternative.parts.detect { |p| p.content_type.downcase == 'text/plain' }
      return plain.body
    elsif plain = msg.parts.detect { |p| p.content_type.downcase == 'text/plain' }
      return plain.body
    else
      msg.body
    end
  end

  def render_message_body(message)
    if message.html_body.to_s.any?
      render_message_html_body(message.html_body)
    else
      render_message_text_body(message.body)
    end
  end

  def render_message_html_body(message_body)
    "<p>#{white_list_with_removal(remove_sensitive_links(hide_contact_details(auto_link(message_body))))}</p>"
  end

  def render_message_text_body(message_body, hide_bulk_quoting=false)
    body = remove_sensitive_links(hide_contact_details(message_body))
    body = remove_bulk_quoting(body) if hide_bulk_quoting
    auto_link(preserve_breaks(remove_excess_breaks(body)))
  end

  def remove_sensitive_links(message_body)
    # To stop email from this group:
    #http://crccfamily.com/groups/364/memberships/25978?code=69V5ZB65iidcs3lUrgdTADX74MqOHuz2UNeVeRSb8w8r3YvZsj&amp;email=off
    message_body.gsub(%r{https?://[^/]+/groups/\d+/memberships/\d+\?code=[^\s]+}, '')
  end
end
