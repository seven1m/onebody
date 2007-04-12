# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def preserve_breaks(text, make_safe=true)
    if make_safe
      text.split(/\n/).map { |part| h(part) }.join('<br/>')
    else
      text.split(/\n/).join('<br/>')
    end
  end
  
  def remove_excess_breaks(text)
    text.gsub(/(\n\s*){3,}/, "\n\n")
  end
  
  def hide_contact_details(text)
    text.gsub(/\(?\d\d\d\)?[\s\-\.]?\d\d\d[\s\-\.]\d\d\d\d/, '[phone number protected]').gsub(/[a-z\-_\.0-9]+@[a-z\-0-9\.]+\.[a-z]{2,4}/, '[email address protected]')
  end
  
  def image_tag(location, options)
    options[:title] = options[:alt] if options[:alt]
    super(location, options)
  end
  
  def select_a_date(name, id, value)
    months = MONTHS.map { |label, num| %(<option value="#{num}" #{value and value.month == num ? 'selected="selected"' : ''}>#{label}</option>) }
    days = (1..31).map { |num| %(<option value="#{num}" #{value and value.day == num ? 'selected="selected"' : ''}>#{num}</option>) }
    years = YEARS.to_a.reverse.map { |num| %(<option value="#{num}" #{value and value.year == num ? 'selected="selected"' : ''}>#{num}</option>) }
    %(<select name="#{name}[month]" id="#{id}_month"><option value="" #{value ? '' : 'selected="selected"'}></option>#{months}</select>
    <select name="#{name}[day]" id="#{id}_day"><option value="" #{value ? '' : 'selected="selected"'}></option>#{days}</select>
    <select name="#{name}[year]" id="#{id}_year"><option value="" #{value ? '' : 'selected="selected"'}></option>#{years}</select>)
  end
  
  def safe_string(s)
    s.untaint
    return s
  end
  alias s safe_string
end
