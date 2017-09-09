class RelationshipsController < ApplicationController
  before_action :only_admins

  def index
    if params[:person_id]
      person_index
    elsif params[:family_id]
      family_index
    else
      render html: t('relationships.no_person_selected'), layout: true
    end
  end

  def person_index
    @person = Person.undeleted.find(params[:person_id])
    @relationships = @person.relationships.includes(:related).order('people.last_name', 'people.first_name')
    @inward_relationships = @person.inward_relationships.includes(:person).order('people.last_name', 'people.first_name')
    @other_names = Relationship.other_names
    @relationship = Relationship.new(person: @person)
    respond_to do |format|
      format.html { render action: 'person_index' }
      format.xml  { render xml: @relationships }
    end
  end

  def family_index
    @family = Family.undeleted.find(params[:family_id])
    people_ids = @family.people.map(&:id)
    @relationships = Relationship.where('person_id in (?) and related_id in (?)', people_ids, people_ids)
    @unique_relationships = {}
    @relationships.each do |relationship|
      @unique_relationships[relationship.related] ||= []
      @unique_relationships[relationship.related] << relationship.name_or_other
      @unique_relationships[relationship.related].uniq!
    end
    @suggested_relationships = @family.suggested_relationships
    render action: 'family_index'
  end

  def create
    if params[:person_id]
      create_for_person
    elsif params[:family_id]
      create_for_family
    else
      render html: t('relationships.no_person_selected'), layout: true
    end
  end

  def create_for_person
    @person = Person.undeleted.find(params[:person_id])
    @related = Person.undeleted.find(Array(params[:ids]).first)
    @relationship = Relationship.new(person: @person, related: @related, name: params[:name], other_name: params[:other_name])
    respond_to do |format|
      if @relationship.save
        format.html { redirect_to person_relationships_path(@person) }
        format.xml  { render xml: @relationship, status: :created, location: person_relationship_path(@person, @relationship) }
      else
        format.html { add_errors_to_flash(@relationship); redirect_to person_relationships_path(@person) }
        format.xml  { render xml: @relationship.errors, status: :unprocessable_entity }
      end
    end
  end

  def create_for_family
    @family = Family.undeleted.find(params[:family_id])
    params[:people].to_a.each do |person_id, relationships|
      relationships.each do |related_id, relationship|
        Relationship.create(
          person:  @family.people.find(person_id),
          related: @family.people.find(related_id),
          name:    relationship
        )
      end
    end
    redirect_to family_relationships_path(@family)
  end

  def destroy
    @person = Person.undeleted.find(params[:person_id])
    @person.relationship.find(params[:id]).destroy
    respond_to do |format|
      format.xml { head :ok }
    end
  end

  def batch
    @person = Person.undeleted.find(params[:person_id])
    params[:ids].to_a.each do |id|
      if relationship = Relationship.where('id = ? and (person_id = ? or related_id = ?)', id, @person.id, @person.id).first
        if params[:delete]
          relationship.destroy
        elsif params[:reciprocate]
          r = relationship.reciprocate
          if r.nil?
            flash[:warning] ||= ''
            flash[:warning] << t('relationships.reciprocate.failure', name: relationship.related.name) + "\n"
          elsif !r.valid?
            add_errors_to_flash(r)
          end
        end
      end
    end
    redirect_to person_relationships_path(@person)
  end

  private

  def only_admins
    unless @logged_in.admin?(:edit_profiles)
      render html: t('only_admins'), layout: true, status: 401
      false
    end
  end
end
