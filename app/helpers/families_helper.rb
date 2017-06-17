module FamiliesHelper
  def family_avatar_path(family, size = :tn)
    if family.try(:photo).try(:exists?)
      family.photo.url(size)
    else
      size = :large unless size == :tn # we only have only two sizes
      image_path("family.#{size}.jpg")
    end
  end

  def family_avatar_tag(family, options = {})
    options.reverse_merge!(size: :tn, alt: family.try(:name))
    options.reverse_merge!(class: "avatar #{options[:size]} #{options[:class]} fit-width")
    options.reverse_merge!(data: { id: "family#{family.id}", size: options[:size] })
    image_tag(family_avatar_path(family, options.delete(:size)), options)
  end

  def show_family_name_suggestion
    @logged_in.admin?(:edit_profiles)          \
    && @family.people.any?                    \
    && @family.suggested_name.present?        \
    && @family.suggested_name != @family.name
  end
end
