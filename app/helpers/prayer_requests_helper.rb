module PrayerRequestsHelper
  include ERB::Util

  def render_prayer_body(req)
	  render_prayer_html_body(req)
  end

  
   def render_prayer_html_body(prayer_body)
    html = auto_link(prayer_body, sanitize: false).html_safe
    html.html_safe
  end
end