module Administration::DashboardsHelper

  def day_word(date)
    today = Date.today
    d = date.to_date
    if d > today
      date.to_s(:date)
    elsif d == today
      'today'
    elsif d == today - 1
      'yesterday'
    elsif d > today - 7
      date.strftime('%A')
    else
      date.to_s(:date)
    end
  end

  def link_to_with_page_prompt(label, url)
    link_to(label, url, :onclick => "if(page=prompt('Page number:', 1))location.href = '#{url}?page=' + page; return false;")
  end

  def display_metric(alert, options={}, &block)
    options.symbolize_keys!
    options.reverse_merge!(:content_tag => :p)
    html = with_output_buffer(&block)
    @alerts << html if alert
    content_tag(options[:content_tag]) { html }
  end

end
