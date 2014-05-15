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
    else
      size = :large unless size == :tn # we only have only two sizes
      img = person.try(:gender) == 'Female' ? 'woman' : 'man'
      image_path("#{img}.#{size}.jpg")
    end
  end

  def avatar_tag(person, options={})
    options.reverse_merge!(size: :tn, alt: person.try(:name))
    options.reverse_merge!(class: "avatar #{options[:size]}")
    image_tag(avatar_path(person, options.delete(:size)), options)
  end
end
