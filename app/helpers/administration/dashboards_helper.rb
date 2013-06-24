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
    link_to(label, url, onclick: "if(page=prompt('Page number:', 1))location.href = '#{url}?page=' + page; return false;")
  end

  def display_metric(alert, options={}, &block)
    options.symbolize_keys!
    options.reverse_merge!(content_tag: :p)
    html = with_output_buffer(&block)
    @alerts << html if alert
    content_tag(options[:content_tag]) { html }
  end

  def metric_alerts
    @alerts.map { |a| "<p>#{a}</p>" }.join("\n").html_safe
  end

  def metric_css_class(count, warn_threshold=nil, critical_threshold=nil)
    if critical_threshold and count >= critical_threshold
      'critical'
    elsif warn_threshold and count > warn_threshold
      'warn'
    else
      ''
    end
  end

  def wrap_metric_count(count)
    count.sub(/\d+/, '<span>\0</span>').html_safe
  end

  def metric(destination, count, warn_threshold=nil, critical_threshold=nil, &block)
    css_class = 'admin-metric ' + metric_css_class(count, warn_threshold, critical_threshold)
    content_tag(:a, href: destination, class: css_class) do
      wrap_metric_count(capture(&block))
    end
  end

end
