module PrayerRequestsHelper
  include ERB::Util

  def render_prayer_body(req)
      render_prayer_html_body(req)
  end

  def render_prayer_html_body(prayer_body)
    html = auto_link(prayer_body, sanitize: false).html_safe
    html.gsub!(/(\-\s){20,}.{0,15}Hit "Reply".+$/m, '')
    html.gsub!(/<blockquote>(\s*[^\s]+.+\s*)<\/blockquote>/mi, "<div class=\"quoted-content\"><div style=\"display:none;\">\\1</div><a href=\"#\" onclick=\"$(this).hide().prev().show();return false;\">#{I18n.t('messages.show_quoted_content')}</a></div>")
    html.gsub!(/<p><p>[^:graph:]*<\/p><\/p>/, '<br/>')
    html.gsub!(/(<br\s?\/?>\s*){3,}/mi, '<br/><br/>')
    html.html_safe
  end
end