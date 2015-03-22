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

  def group_ids
    @group_ids ||= checkin_times.flat_map { |t| t.group_times.pluck(:group_id) }.uniq
  end

  def all_attendance_records(person)
    person.attendance_records
      .includes(:group)
      .where(
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
      people:     people_as_json,
      times:      checkin_times.decorate.as_json,
      selections: selections.as_json,
      labels:     checkin_labels_as_json
    }
  end

  def checkin_labels_as_json
    CheckinLabel.all.each_with_object({}) do |label, hash|
      hash[label.id] = label.xml
    end
  end

  def people_as_json
    people.map do |person|
      person.as_json.merge(
        avatar: avatar(person),
        attendance_records: attendance_records(person),
        can_choose_same: can_choose_same?(person)
      )
    end
  end

  def selections
    people.each_with_object({}) do |person, people_hash|
      records = all_attendance_records(person).to_a
      h = people_hash[person.id] = {}
      checkin_times.each do |time|
        record = records.detect { |a| a.checkin_time_id == time.id }
        next unless record
        h[time.id] = group_time_for_attendance_record(record)
      end
    end
  end

  def group_time_for_attendance_record(record)
    group_time = GroupTime
      .where(
        checkin_time_id: record.checkin_time_id,
        group_id: record.group_id
      )
      .first
    group_time.as_json.merge(
      group: {
        name: group_time.group.name
      }
    )
  end

  def people
    family.people.undeleted.minimal
  end

  def avatar(person)
    person.photo.url(:tn) if person.photo.exists?
  end

  private

  def checkin_times
    @checkin_times ||= CheckinTime.where(campus: @campus)
      .where(
        "(the_datetime is null and weekday = :today) or
         (the_datetime between :from and :to)",
        today: Time.current.wday,
        from:  Time.current - 1.hour,
        to:    Time.current + 4.hours
      )
  end
end
