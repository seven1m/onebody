module Administration::Checkin::TimesHelper
  def checkin_time_campuses
    [[t('checkin.times.edit.campus.new'), '!']] + CheckinTime.campuses.map { |c| [c, c] }
  end
end
