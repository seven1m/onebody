class Stats::AttendanceGraphPresenter
  def initialize(range = 30.days, checked_in: false, by_hour: false)
    @range      = range
    @checked_in = checked_in
    @by_hour    = by_hour
  end

  def as_json(*_args)
    {
      data: data,
      times: times
    }
  end

  def data
    (0...range_count).each_with_object({}) do |increment, hash|
      group = (@by_hour ? increment.hours.ago : increment.days.ago).strftime(format)
      hash[group] = grouped[group] || 0
    end.values.reverse
  end

  def times
    (0...range_count).map do |increment|
      (@by_hour ? increment.hours.ago : increment.days.ago).strftime(format)
    end.reverse
  end

  private

  def range_count
    count = @range.to_i / 60 / 60
    @by_hour ? count : (count / 24)
  end

  def grouped
    @grouped ||= records.each_with_object({}) do |record, hash|
      attended_at = record['attended_at']
      attended_at = Time.parse(attended_at) if attended_at.is_a?(String) # postgres
      group = attended_at.strftime(format)
      hash[group] ||= 0
      hash[group] += 1
    end
  end

  def format
    @by_hour ? '%Y-%m-%d %H:00' : '%Y-%m-%d'
  end

  def records
    AttendanceRecord
      .connection
      .select_all(
        "select attended_at
         from attendance_records
         where site_id = #{Site.current.id}
         and attended_at >= '#{@range.ago}'
         #{@checked_in ? 'and checkin_time_id is not null' : ''}
         order by attended_at desc"
      )
      .to_a
  end
end
