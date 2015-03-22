class CheckinTimeDecorator < Draper::Decorator
  delegate_all

  def time_to_s
    object.time_to_s.sub(/^0/, '')
  end

  def group_times_as_json
    object
      .all_group_times
      .includes(:group, :checkin_folder)
      .references(:group)
      .order(:sequence)
      .map do |gt|
        gt.as_json.merge(
          section_name: gt.checkin_folder.try(:name),
          group: {
            name: gt.group.name
          }
        )
      end
  end

  def as_json
    object.as_json.merge(
      time:     time_to_s,
      sections: group_times_as_json.group_by { |gt| gt[:section_name] }
    )
  end
end
