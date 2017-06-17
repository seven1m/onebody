module PeopleHelper
  include StreamsHelper

  def linkify(text, attribute)
    text = h(text)
    text.split(/,\s*/).map do |item|
      link_to item, search_path(attribute => item)
    end
  end

  def show_attribute?(attribute)
    @person.send(attribute).present? &&
      @person.show_attribute_to?(attribute, @logged_in)
  end

  def show_attribute(attribute, &block)
    capture(&block) if show_attribute?(attribute)
  end

  alias attribute show_attribute # TODO: remove this

  def showing_attribute_because_admin?(attribute)
    show_attribute?(attribute) &&
      @person.respond_to?("share_#{attribute}?") &&
      @person.send("share_#{attribute}?") == false &&
      @logged_in.admin?(:view_hidden_properties)
  end

  def showing_attribute_because_admin_icon(attribute)
    return unless showing_attribute_because_admin?(attribute)
    icon('fa fa-lock text-gray with-title', title: t('people.show.showing_hidden_attribute.tooltip'))
  end

  def person_title(person)
    if person.description.present?
      t('people.title_html', name: person.name_and_nick, description: person.description)
    else
      person.name_and_nick
    end
  end

  def business_categories
    [[t('people.edit.business_category.new'), '!']] + Person.business_categories.map { |c| [c, c] }
  end

  def custom_types
    [[t('people.edit.custom_type.new'), '!']] + Person.custom_types.map { |t| [t, t] }
  end

  def has_type?(person)
    person.elder? || person.deacon? || person.staff? || person.member? || person.custom_type.present?
  end

  def avatar_path(person, size = :tn, variation = nil)
    if person.is_a?(Family)
      family_avatar_path(person, size)
    elsif person.is_a?(Group)
      group_avatar_path(person, size)
    elsif person.is_a?(Album)
      album_avatar_path(person, size)
    else
      if person.try(:photo).try(:exists?)
        person.photo.url(size)
      else
        size = :large unless size == :tn # we only have only two sizes
        img = person.try(:gender) == 'Female' ? 'woman' : 'man'
        if variation == :dark
          image_path("#{img}.dark.#{size}.png")
        else
          image_path("#{img}.#{size}.jpg")
        end
      end
    end
  end

  def avatar_tag(person, options = {})
    return if person.nil?
    if person.is_a?(Family)
      family_avatar_tag(person, options)
    elsif person.is_a?(Group)
      group_avatar_tag(person, options)
    elsif person.is_a?(Album)
      album_avatar_tag(person, options)
    else
      options.reverse_merge!(size: :tn, alt: person.try(:name))
      options.reverse_merge!(class: "avatar #{options[:size]} #{options[:class]}")
      options.reverse_merge!(data: { id: "person#{person.id}", size: options[:size] })
      fallback_to_family = options.delete(:fallback_to_family)
      path = if !person.try(:photo).try(:exists?) && fallback_to_family && person.try(:family).try(:photo).try(:exists?)
               family_avatar_path(person.family)
             else
               avatar_path(person, options.delete(:size), options.delete(:variation))
             end
      image_tag(path, options)
    end
  end

  def link_to_person_role(person, options = {})
    options.reverse_merge!(separator: ' ')
    roles = []
    if Setting.get(:features, :custom_person_type) && person.custom_type.present?
      roles << person.custom_type
    end
    roles += %w(elder deacon staff member).select do |role|
      person.send("#{role}?")
    end
    if options[:only_one]
      link_to_role(roles.first)
    else
      roles.map { |r| link_to_role(r) }.join(options[:separator]).html_safe
    end
  end

  def link_to_role(role)
    link_to search_path(type: role) do
      icon('fa fa-star') + ' ' +
        t(role, scope: 'people.roles', default: role)
    end
  end

  def submit_or_save_button
    label = if Setting.get(:features, :updates_must_be_approved) && !@logged_in.admin?(:edit_profiles)
              t('submit_changes')
            else
              t('save_changes')
    end
    button_tag label, class: 'btn btn-success'
  end

  def has_social_networks?(person)
    person.twitter.present? || person.facebook_url.present?
  end

  def twitter_url(person)
    return unless person.twitter.present?
    "https://twitter.com/#{person.twitter}"
  end

  def custom_field_date_format(string)
    Date.parse(string).to_s(:date)
  rescue ArgumentError, TypeError
    nil
  end
end
