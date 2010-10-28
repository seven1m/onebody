formats = {
  :default           => "%m/%d/%Y %I:%M %p",
  :date              => "%m/%d/%Y",
  :time              => "%I:%M %p",
  :date_without_year => "%m/%d"
}

Time::DATE_FORMATS.merge!(formats)
Date::DATE_FORMATS.merge!(formats)

MONTHS_FOR_SELECT = Date::ABBR_MONTHNAMES.with_indexes[1..-1]
