class RelationshipsController < ApplicationController
  before_filter :only_admins
  
  def index
    @person = Person.find_by_id_and_deleted(params[:person_id], false)
    if @logged_in.can_see?(@person)
      @relationships = @person.relationships.all(:include => :related, :order => 'people.last_name, people.first_name')
      @inward_relationships = @person.inward_relationships.all(:include => :person, :order => 'people.last_name, people.first_name')
      @other_names = Relationship.other_names
      @relationship = Relationship.new(:person => @person)
    else
      render :text => 'You are not authorized to view this person.', :layout => true, :status => 401
    end
  end
  
  def create
    @person = Person.find_by_id_and_deleted(params[:person_id], false)
    if @logged_in.can_see?(@person)
      if @related = Person.find_by_id_and_deleted(params[:ids].to_a.first, false)
        @relationship = Relationship.create(:person => @person, :related => @related, :name => params[:name], :other_name => params[:other_name])
        if @relationship.errors.any?
          add_errors_to_flash(@relationship)
        end
      end
      redirect_to person_relationships_path(@person)
    else
      render :text => 'You are not authorized.', :layout => true, :status => 401
    end
  end
  
  def batch
    @person = Person.find_by_id_and_deleted(params[:person_id], false)
    if @logged_in.can_see?(@person)
      params[:ids].to_a.each do |id|
        if relationship = Relationship.first(:conditions => ["id = ? and (person_id = ? or related_id = ?)", id, @person.id, @person.id])
          if params[:delete]
            relationship.destroy
          elsif params[:reciprocate]
            r = relationship.reciprocate
            if r.nil?
              flash[:warning] ||= ''
              flash[:warning] << I18n.t('relationships.cannot_be_reciprocated', :name => relationship.related.name) + "\n"
            elsif !r.valid?
              add_errors_to_flash(r)
            end
          end
        end
      end
      redirect_to person_relationships_path(@person)
    else
      render :text => 'You are not authorized.', :layout => true, :status => 401
    end
  end
  
end
