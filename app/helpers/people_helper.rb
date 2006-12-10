module PeopleHelper
  def linkify(text, attribute)
    text.split(/,\s*/).map do |item|
      link_to h(item), :action => 'search', attribute => item
    end.join ', '
  end
end
