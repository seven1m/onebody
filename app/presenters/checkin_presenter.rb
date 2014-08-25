class CheckinPresenter
  extend ActiveModel::Naming

  attr_reader :campus, :family

  def initialize(campus, family)
    @campus = campus
    @family = family
  end

  def id
    family.id
  end

  def times
    checkin_times.decorate
  end

  def all_attendance_records(person)
    group_ids = checkin_times.flat_map { |t| t.group_times.pluck(:group_id) }.uniq
    person.attendance_records.where(
      group_id:        group_ids,
      checkin_time_id: checkin_times.pluck(:id)
    )
  end

  def attendance_records(person, times=nil)
    times ||= checkin_times.map(&:to_time)
    all_attendance_records(person).where(
      attended_at: times
    )
  end

  def can_choose_same?(person)
    checkin_times.all?(&:weekday) and last_week_records(person).any?
  end

  def last_week_records(person)
    times = checkin_times.where(the_datetime: nil).map { |ct| ct.to_time - 1.week }
    attendance_records(person, times)
  end

  def as_json(*args)
    {
      people: people_as_json,
      times: checkin_times.decorate.as_json
    }
  end

  def people_as_json
    family.people.undeleted.minimal.map do |person|
      person.as_json.merge(
        avatar: avatar(person),
        attendance_records: attendance_records(person),
        can_choose_same: can_choose_same?(person)
      )
    end
  end

  def avatar(person)
    person.photo.url(:tn) if person.photo.exists?
  end

  private

  def checkin_times
    CheckinTime.where(campus: @campus)
      .where(
        "(the_datetime is null and weekday = :today) or
         (the_datetime between :from and :to)",
        today: Time.current.wday,
        from:  Time.current - 1.hour,
        to:    Time.current + 4.hours
      )
  end

end
