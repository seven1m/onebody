ActiveSupport::CoreExtensions::Time::Conversions::DATE_FORMATS.merge!(
  :default => "%m/%d/%Y %I:%M %p",
  :date => "%m/%d/%Y",
  :time => "%I:%M %p"
)

MONTHS_FOR_SELECT = Date::ABBR_MONTHNAMES.with_indexes[1..-1]
