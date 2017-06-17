module Administration::DashboardsHelper
  def link_to_with_page_prompt(label, url)
    link_to(label, url, onclick: "if(page=prompt('Page number:', 1))location.href = '#{url}?page=' + page; return false;")
  end

  def metric_alerts
    @alerts.map { |a| "<p>#{a}</p>" }.join("\n").html_safe
  end

  def metric_css_class(count, warn_threshold = nil, critical_threshold = nil)
    count = count.to_i
    if critical_threshold && count >= critical_threshold
      'critical'
    elsif warn_threshold && count > warn_threshold
      'warn'
    else
      ''
    end
  end

  def wrap_metric_count(count)
    count.sub(/\d+/, '<span>\0</span>').html_safe
  end

  def metric(destination, count, warn_threshold = nil, critical_threshold = nil, &block)
    css_class = 'admin-metric ' + metric_css_class(count, warn_threshold, critical_threshold)
    content_tag(:a, href: destination, class: css_class) do
      wrap_metric_count(capture(&block))
    end
  end
end
