module PeopleHelper
  include StreamsHelper

  def linkify(text, attribute)
    text = h(text)
    text.split(/,\s*/).map do |item|
      link_to item, search_path(attribute => item)
    end
  end

  def attribute(attribute, &block)
    if @person.send(attribute).to_s.any? && @person.show_attribute_to?(attribute, @logged_in)
      capture(&block)
    end
  end

  def business_categories
    Person.business_categories
  end

  def custom_types
    Person.custom_types
  end
end
