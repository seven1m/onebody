class GroupiesController < ApplicationController

  def index
    @person = Person.find(params[:person_id])
    if @logged_in.can_see?(@person)
      @people = @person.sidebar_group_people.select { |p| @logged_in.can_see?(p) }
    else
      render :text => 'Person not found.', :layout => true, :status => 404
    end
  end

end
