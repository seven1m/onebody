class CalendarsController < ApplicationController
  
  def show
    #people/{person_id}/calendars
    @person = Person.find(params[:person_id])
  end
  
end
