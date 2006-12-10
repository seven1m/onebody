# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def preserve_breaks(text)
    text.split(/\n/).map { |part| h(part) }.join('<br/>')
  end
  
  def image_tag(location, options)
    options[:title] = options[:alt] if options[:alt]
    super(location, options)
  end
end
