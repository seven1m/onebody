class CheckinPresenter
  extend ActiveModel::Naming

  attr_reader :campus, :person

  def initialize(campus, person)
    @campus = campus
    @person = person
  end

  def id
    person.id
  end

  def times
    #Timecop.freeze(Time.local(2014, 6, 29, 9, 00)) # TEMP for testing the UI
    CheckinTime.where(campus: @campus)
      .where(
        "(the_datetime is null and weekday = ?) or
         (the_datetime between ? and ?)",
        Time.now.wday,
        Time.now - 1.hour,
        Time.now + 4.hours
      )
      .decorate
  end

end
