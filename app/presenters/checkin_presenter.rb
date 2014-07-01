class CheckinPresenter
  extend ActiveModel::Naming

  attr_reader :campus, :person

  def initialize(campus, person)
    @campus = campus
    @person = person
  end

  def id
    person.id
  end

  def times
    checkin_times.decorate
  end

  def attendance_records
    group_ids = checkin_times.flat_map { |t| t.group_times.pluck(:group_id) }.uniq
    person.attendance_records.where(group_id: group_ids, checkin_time_id: checkin_times.pluck(:id))
  end

  private

  def checkin_times
    Timecop.freeze(Time.local(2014, 6, 29, 9, 00)) # TEMP for testing the UI
    CheckinTime.where(campus: @campus)
      .where(
        "(the_datetime is null and weekday = ?) or
         (the_datetime between ? and ?)",
        Time.now.wday,
        Time.now - 1.hour,
        Time.now + 4.hours
      )
  end

end
