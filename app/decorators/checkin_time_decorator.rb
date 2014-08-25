class CheckinTimeDecorator < Draper::Decorator

  delegate_all

  def time_to_s
    object.time_to_s.sub(/^0/, '')
  end

  def group_times
    object.group_times.includes(:group).references(:group).order("section, groups.name").group_by(&:section)
  end

  def as_json
    object.as_json.merge(
      time:     time_to_s,
      sections: group_times
    )
  end

end
