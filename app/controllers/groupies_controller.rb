class GroupiesController < ApplicationController

  def index
    @person = Person.find(params[:person_id])
    if @logged_in.can_see?(@person)
      @people = @person.small_group_people.order(:last_name, :first_name).select { |p| @logged_in.can_see?(p) }
    else
      render text: t('people.not_found'), layout: true, status: 404
    end
  end

end
