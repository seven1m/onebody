module Api
  module V2
    class CheckinTimeResource < OneBodyResource
      attributes :weekday, :time, :the_datetime, :campus

    end
  end
end