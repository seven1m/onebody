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
  
  def bar_chart_url(data, options={})
    options.symbolize_keys!
    options.reverse_merge!(:set_count => 1, :set_labels => nil, :width => 400, :height => 200, :title => '', :colors => ['4F9EC9', '79B933', 'FF9933'])
    labels = data.map { |p| p[0] }
    counts = []
    (0...options[:set_count]).each do |set|
      counts[set] = data.map { |p| p[set+1] }
    end
    max = data.map { |p| p[1..-1].sum }.max
    "http://chart.apis.google.com/chart?chtt=#{options[:title]}&cht=bvs&chxt=x,y&chxr=1,0,#{max}#{options[:interval] && ','+options[:interval].to_s}&chds=0,#{max}&chd=t:#{counts.map { |c| c.join(',') }.join('|')}&chs=#{options[:width]}x#{options[:height]}&chl=#{labels.join('|')}&chbh=a&chco=#{options[:colors].join(',')}" + (options[:set_labels] ? "&chdl=#{options[:set_labels].join('|')}" : '')
  end
  
  def pie_chart_url(data, options={})
    options.symbolize_keys!
    options.reverse_merge!(:width => 350, :height => 200, :title => '', :colors => ['4F9EC9', '79B933', 'FF9933'])
    labels = data.keys
    counts = labels.inject([]) { |a, l| a << data[l]; a }
    labels.map! { |l| l.to_s.gsub('_', ' ') }
    "http://chart.apis.google.com/chart?chtt=#{options[:title]}&cht=p&chd=t:#{counts.join(',')}&chs=#{options[:width]}x#{options[:height]}&chl=#{labels.join('|')}&chco=#{options[:colors].join(',')}"
  end
  
end
