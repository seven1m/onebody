MONTHS = [
  ['January',  1],
  ['February',  2],
  ['March',  3],
  ['April',  4],
  ['May',  5],
  ['June',  6],
  ['July',  7],
  ['August',  8],
  ['September',  9],
  ['October',  10],
  ['November',  11],
  ['December',  12],
]
YEARS = (Date.today.year-120)..Date.today.year

ActiveSupport::CoreExtensions::Time::Conversions::DATE_FORMATS.merge!(
  :default => "%m/%d/%Y %I:%M %p",
  :date => "%m/%d/%Y"
)