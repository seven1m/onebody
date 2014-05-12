module PeopleHelper
  include StreamsHelper

  def linkify(text, attribute)
    text = h(text)
    text.split(/,\s*/).map do |item|
      link_to item, search_path(attribute => item)
    end
  end

  def show_attribute?(attribute, &block)
    if @person.send(attribute).to_s.any? && @person.show_attribute_to?(attribute, @logged_in)
      capture(&block)
    end
  end

  alias_method :attribute, :show_attribute? # TODO remove this

  def business_categories
    Person.business_categories
  end

  def custom_types
    Person.custom_types
  end

  def avatar_path(person, size=:tn)
    if person.try(:photo).try(:exists?)
      person.photo.url(size)
    elsif person.try(:gender) == 'Female'
      image_path("clean/womanoutline.#{size}.png")
    else
      image_path("clean/manoutline.#{size}.png")
    end
  end

  def avatar_tag(person, options={})
    options.reverse_merge!(size: :tn, alt: person.try(:name))
    image_tag(avatar_path(person, options.delete(:size)), options)
  end
end
