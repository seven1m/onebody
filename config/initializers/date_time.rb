ActiveSupport::CoreExtensions::Time::Conversions::DATE_FORMATS.merge!(
  :default           => "%m/%d/%Y %I:%M %p",
  :date              => "%m/%d/%Y",
  :time              => "%I:%M %p",
  :date_without_year => "%m/%d"
)

MONTHS_FOR_SELECT = Date::ABBR_MONTHNAMES.with_indexes[1..-1]
