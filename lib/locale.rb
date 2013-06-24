module OneBody

  def set_locale
    I18n.locale = Setting.get(:system, :language)
  end

  def set_time_zone
    Time.zone = Setting.get(:system, :time_zone)
  end

  def set_local_formats
    formats = {
      full:              Setting.get(:formats, :full_date_and_time),
      date:              Setting.get(:formats, :date),
      time:              Setting.get(:formats, :time),
      date_without_year: Setting.get(:formats, :date_without_year)
    }
    Time::DATE_FORMATS.merge!(formats)
    Date::DATE_FORMATS.merge!(formats)
  end

  module_function :set_locale, :set_time_zone, :set_local_formats

end
