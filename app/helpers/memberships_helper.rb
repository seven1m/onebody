module MembershipsHelper
  def manually_added_person_in_linked_group_alert_icon(group, membership)
    return unless (group.linked? || group.parents_of?) && !membership.auto?
    icon(
      'fa fa-exclamation-circle text-gray',
      title: t('memberships.index.details.manual.tooltip')
    )
  end
end
