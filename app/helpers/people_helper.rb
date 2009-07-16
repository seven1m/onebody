module PeopleHelper
  include StreamsHelper
  def linkify(text, attribute)
    text.split(/,\s*/).map do |item|
      link_to h(item), search_path(attribute => item), :class => 'no-underline'
    end.join ', '
  end
end
