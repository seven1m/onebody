class RelationshipsController < ApplicationController
  before_filter :only_admins
  
  def index
    @person = Person.find_by_id_and_deleted(params[:person_id], false)
    if @logged_in.can_see?(@person)
      @relationships = @person.relationships.all(:include => :related)
      @relationship = Relationship.new(:person => @person)
    else
      render :text => 'You are not authorized to view this person.', :layout => true, :status => 401
    end
  end
  
  def create
    @person = Person.find_by_id_and_deleted(params[:person_id], false)
    if @logged_in.can_see?(@person)
      params[:ids].each do |id|
        if @related = Person.find_by_id_and_deleted(id, false)
          @relationship = Relationship.create(:person => @person, :related => @related, :name => params[:name], :other_name => params[:other_name])
          if @relationship.errors.any?
            add_errors_to_flash(@relationship)
            break
          end
        else
          render :text => 'There was an error.', :layout => true
          return
        end
      end
      redirect_to person_relationships_path(@person)
    else
      render :text => 'You are not authorized.', :layout => true, :status => 401
    end
  end
  
  def destroy
    @person = Person.find_by_id_and_deleted(params[:person_id], false)
    if @logged_in.can_see?(@person)
      @person.relationships.find(params[:id]).destroy
      redirect_to person_relationships_path(@person)
    else
      render :text => 'You are not authorized.', :layout => true, :status => 401
    end
  end
  
end
