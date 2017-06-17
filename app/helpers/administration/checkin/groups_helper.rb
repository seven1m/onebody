module Administration::Checkin::GroupsHelper
  def checkin_group_sections
    [[t('checkin.groups.section.new'), '!']] + GroupTime.where("coalesce(section, '') != ''").distinct(:section).pluck(:section)
  end
end
