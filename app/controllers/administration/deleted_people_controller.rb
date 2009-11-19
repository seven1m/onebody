class Administration::DeletedPeopleController < ApplicationController
  before_filter :only_admins
  
  VALID_SORT_COLS = [
    'people.id',
    'people.legacy_id',
    'people.last_name',
    'people.first_name',
    'people.family_id',
    'people.legacy_family_id',
    'families.name',
    'families.deleted',
    'people.updated_at desc'
  ]
  
  def index
    unless params[:sort].to_s.split(',').all? { |col| VALID_SORT_COLS.include?(col) }
      params[:sort] = 'people.updated_at desc'
    end
    @people = Person.paginate(:include => :family, :conditions => {:deleted => true}, :order => params[:sort], :page => params[:page])
    @families = Family.all(:conditions => ["deleted = ? and (select count(id) from people where deleted = ? and family_id=families.id) = 0", false, false], :order => 'name')
  end
  
  def batch
    params[:ids].to_a.each do |id|
      person = Person.find(id)
      if params[:undelete]
        person.family.update_attribute(:deleted, false) if person.family.deleted?
        person.update_attribute(:deleted, false) if person.deleted?
      elsif params[:purge]
        unless person.deleted?
          render :text => 'Person not deleted.', :layout => true, :status => 401
          return
        end
        person.destroy_for_real
        if params[:purge_empty_families] and person.family.people.count == 0
          person.family.destroy_for_real
        end
      end
    end
    redirect_to administration_deleted_people_path
  end
  
  private
  
    def only_admins
      unless @logged_in.admin?(:edit_profiles)
        render :text => 'You must be an administrator to use this section.', :layout => true, :status => 401
        return false
      end
    end

end
