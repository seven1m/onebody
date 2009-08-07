module PeopleHelper
  include StreamsHelper
  def linkify(text, attribute)
    text = h(text)
    text.split(/,\s*/).map do |item|
      link_to item, search_path(attribute => item), :class => 'no-underline'
    end.join ', '
  end
end
