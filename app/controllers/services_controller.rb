class ServicesController < ApplicationController

  # TODO to be implemented
  def index
    # people/1/participations
     if params[:person_id]
       @person = Person.find(params[:person_id])
       respond_to do |format|
         format.js { render :partial => 'person_services' }
         format.html { render :partial => 'person_services', :layout => true }
         if can_export?
           format.xml { render :xml => @person.participations.to_xml(:except => %w(site_id)) }
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
    if params[:person_id] and params[:service_category_id]
      
      @person = Person.find(params[:person_id])
      @service_category = ServiceCategory.find(params[:service_category_id])
      
      @service = Service.find_or_initialize_by_person_id_and_service_category_id(
        @person.id, @service_category.id
      )

      case params[:receiving_element]
      when 'current'
        @service.status = 'current'
      when 'pending'
        @service.status = 'pending'
      when 'historical'
        @service.status = 'completed'
      end
      @service.save!

      @services = ServiceCategory.find(:all, :order => :name)
      @services.delete_if{|sp| @person.service_categories.include?(sp)}
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
      @service = Service.find params[:id]
    elsif params[:id].to_i == 0 and params[:person_id] and params[:service_category_id]
      
      @person = Person.find(params[:person_id])
      @service_category = ServiceCategory.find(params[:service_category_id])
      
      @service = Service.find_by_person_id_and_service_category_id(
        @person.id, @service_category.id
      )
    end

    unless @service.nil?
      @service.destroy
      @services = ServiceCategory.find(:all, :order => :name)
      @services.delete_if{|sp| @person.service_categories.include?(sp)}
    end

    respond_to do |format|
      format.js
    end
  end  
  
end