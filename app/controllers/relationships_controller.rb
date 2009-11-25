class RelationshipsController < ApplicationController
  before_filter :only_admins
  
  def index
    if params[:person_id]
      person_index
    elsif params[:family_id]
      family_index
    else
      render :text => 'No person selected.', :layout => true
    end
  end
  
  def person_index
    @person = Person.find_by_id_and_deleted(params[:person_id], false)
    if @logged_in.can_see?(@person)
      @relationships = @person.relationships.all(:include => :related, :order => 'people.last_name, people.first_name')
      @inward_relationships = @person.inward_relationships.all(:include => :person, :order => 'people.last_name, people.first_name')
      @other_names = Relationship.other_names
      @relationship = Relationship.new(:person => @person)
      render :action => 'person_index'
    else
      render :text => 'You are not authorized to view this person.', :layout => true, :status => 401
    end
  end
  
  def family_index
    @family = Family.find_by_id_and_deleted(params[:family_id], false)
    if @logged_in.can_see?(@family)
      people_ids = @family.people.map { |p| p.id }
      @relationships = Relationship.all(:conditions => ["person_id in (?) and related_id in (?)", people_ids, people_ids])
      @unique_relationships = {}
      @relationships.each do |relationship|
        @unique_relationships[relationship.related] ||= []
        @unique_relationships[relationship.related] << relationship.name_or_other
        @unique_relationships[relationship.related].uniq!
      end
      @suggested_relationships = @family.suggested_relationships
      render :action => 'family_index'
    else
      render :text => 'You are not authorized to view this family.', :layout => true, :status => 401
    end
  end
  
  def create
    if params[:person_id]
      create_for_person
    elsif params[:family_id]
      create_for_family
    else
      render :text => 'No person selected.', :layout => true
    end
  end
  
  def create_for_person
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
  
  def create_for_family
    @family = Family.find_by_id_and_deleted(params[:family_id], false)
    if @logged_in.can_see?(@family)
      params[:people].each do |person_id, relationships|
        relationships.each do |related_id, relationship|
          Relationship.create(
            :person  => @family.people.find(person_id),
            :related => @family.people.find(related_id),
            :name    => relationship
          )
        end
      end
      redirect_to family_relationships_path(@family)
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
  
  private
  
    def only_admins
      unless @logged_in.admin?(:edit_profiles)
        render :text => 'You must be an administrator to use this section.', :layout => true, :status => 401
        return false
      end
    end
  
end
