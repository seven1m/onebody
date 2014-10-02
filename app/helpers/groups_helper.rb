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
    options.reverse_merge!(data: { id: "group#{group.id}", size: options[:size] })
    image_tag(group_avatar_path(group, options.delete(:size)), options)
  end

  def group_categories
    [[t('groups.edit.category.new'), '!']] + Group.categories.keys
  end

  def must_request_group_join?(group)
    not group.admin?(@logged_in) and @group.approval_required_to_join?
  end

  NEW_GROUP_AGE = 5.days

  def new_groups
    if @logged_in.admin?(:manage_groups)
      Group.recent(NEW_GROUP_AGE)
    else
      Group.is_public.recent(NEW_GROUP_AGE)
    end
  end

  def group_content_column(&block)
    count = [@group.email?, @group.prayer?, @group.pictures?, @group.has_tasks?].count { |t| t }
    return if count == 0
    width = [12 / count, 6].min
    if width <= 3
      cls = "col-md-6"
    else
      cls = "col-md-#{width}"
    end
    content_tag(:div, class: "#{cls} print-inline-block", &block)
  end

  def group_membership_modes
    t('groups.edit.advanced.membership_mode.options').dup.tap { |options|
      options.delete(:adults) if Person.undeleted.adults.count > Group::EVERYONE_LIMIT
    }.invert
  end

end
