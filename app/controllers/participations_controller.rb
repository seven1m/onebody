class ParticipationsController < ApplicationController

  # TODO to be implemented
  def index
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
    end

    respond_to do |format|
      format.js
    end
  end
  
  # TODO to be implemented
  def edit
  end
  
  # TODO to be implemented
  def update
  end
  
  def destroy
    if params[:id].to_i != 0
      @participation = Participation.find params[:id]
    elsif params[:id].to_i == 0 and params[:person_id] and params[:participation_category_id]
      
      @person = Person.find(params[:person_id])
      @participation_category = ParticipationCategory.find(params[:participation_category_id])
      
      @participation = Participation.find_by_person_id_and_participation_category_id(
        @person.id, @participation_category.id
      )
    end

    unless @participation.nil?
      @participation.destroy
      @participation_categories = ParticipationCategory.find(:all, :order => :name)
      @participation_categories.delete_if{|pp| @person.participation_categories.include?(pp)}
    end

    respond_to do |format|
      format.js
    end
  end  
  
end