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

  def all_attendance_records
    group_ids = checkin_times.flat_map { |t| t.group_times.pluck(:group_id) }.uniq
    person.attendance_records.where(
      group_id:        group_ids,
      checkin_time_id: checkin_times.pluck(:id)
    )
  end

  def attendance_records(times=nil)
    times ||= checkin_times.map { |ct| ct.to_time }
    all_attendance_records.where(
      attended_at: times
    )
  end

  def can_choose_same?
    checkin_times.all? { |ct| ct.weekday } and last_week_records.any?
  end

  def last_week_records
    times = checkin_times.where(the_datetime: nil).map { |ct| ct.to_time - 1.week }
    attendance_records(times)
  end

  private

  def checkin_times
    zone = ActiveSupport::TimeZone.new(Setting.get(:system, :time_zone))
    local_time = Time.now.in_time_zone(zone)
    CheckinTime.where(campus: @campus)
      .where(
        "(the_datetime is null and weekday = ?) or
         (the_datetime between ? and ?)",
        local_time.wday,
        local_time - 1.hour,
        local_time + 4.hours
      )
  end

end
