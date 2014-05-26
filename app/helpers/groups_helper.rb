module GroupsHelper
  include StreamsHelper

  def group_box_class(group)
    if group.private?
      'box-danger'
    elsif group.hidden?
      'box-warning'
    else
      'box-success'
    end
  end

  def group_avatar_path(group, size=:tn)
    if group.try(:photo).try(:exists?)
      group.photo.url(size)
    else
      size = :large unless size == :tn # we only have only two sizes
      image_path("group.#{size}.jpg")
    end
  end

  def group_avatar_tag(group, options={})
    options.reverse_merge!(size: :tn, alt: group.try(:name))
    options.reverse_merge!(class: "avatar #{options[:size]} #{options[:class]}")
    image_tag(group_avatar_path(group, options.delete(:size)), options)
  end

  def group_categories
    [[t('groups.edit.category.new'), '!']] + Group.categories.keys
  end

end
