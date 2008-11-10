class ParticipationsController < ApplicationController
  
  def index
    # people/1/participations
    if params[:person_id]
      @person = Person.find(params[:person_id])
      respond_to do |format|
        format.js   { render :partial => 'person_participations' }
        format.html { render :partial => 'person_participations', :layout => true }
        if can_export?
          format.xml { render :xml =>  @person.participations.to_xml(:except => %w(site_id)) }
          format.csv { render :text => @person.participations.to_csv(:except => %w(site_id)) }
        end
      end
    # regular index
    else
      # TODO: to be implemented
    end
  end
    
  # TODO to be implemented
  def show
  end
  
  # TODO to be implemented
  def new
  end
  
  def create
    if params[:person_id] and params[:participation_category_id]
      
      @person = Person.find(params[:person_id])
      @participation_category = ParticipationCategory.find(params[:participation_category_id])
      
      @participation = Participation.find_or_initialize_by_person_id_and_participation_category_id(
        @person.id, @participation_category.id
      )

      case params[:receiving_element]
      when 'current'
        @participation.status = 'current'
      when 'pending'
        @participation.status = 'pending'
      when 'historical'
        @participation.status = 'completed'
      end
      @participation.save!

      @participation_categories = ParticipationCategory.find(:all, :order => :name)
      @participation_categories.delete_if{|pp| @person.participation_categories.include?(pp)}

      respond_to do |format|
        format.js
      end
    end
  end
  
  # TODO to be implemented
  def edit
  end
  
  # TODO to be implemented
  def update
  end
  
  def destroy
    if params[:person_id] and params[:participation_category_id]
      
      @person = Person.find(params[:person_id])
      @participation_category = ParticipationCategory.find(params[:participation_category_id])
      
      @participation = Participation.find_by_person_id_and_participation_category_id(
        @person.id, @participation_category.id
      )
      @participation.destroy

      @participation_categories = ParticipationCategory.find(:all, :order => :name)
      @participation_categories.delete_if{|pp| @person.participation_categories.include?(pp)}

      respond_to do |format|
        format.js
      end
    end
  end  
  
end