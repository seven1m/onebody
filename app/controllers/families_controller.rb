class FamiliesController < ApplicationController
  
  cache_sweeper :person_sweeper, :family_sweeper, :only => %w(create update destroy)
  
  def index
    respond_to do |format|
      format.html { redirect_to @logged_in }
      if can_export?
        @families = Family.paginate(:order => 'last_name, name', :page => params[:page], :per_page => params[:per_page] || MAX_EXPORT_AT_A_TIME)
        format.xml { render :xml  => @families.to_xml(:include => [:people], :except => %w(site_id)) }
        format.csv { render :text => @families.to_csv(:except => %w(site_id)) }
      end
    end
  end
  
  def show
    if params[:legacy_id]
      @family = Family.find_by_legacy_id(params[:id])
    else
      @family = Family.find_by_id(params[:id])
    end
    raise ActiveRecord::RecordNotFound unless @family
    @people = @family.people.all.select { |p| @logged_in.can_see? p }
    if @logged_in.can_see?(@family)
      respond_to do |format|
        format.html
        format.xml { render :xml => @family.to_xml } if can_export?
      end
    else
      render :text => 'Family not found.', :status => 404
    end
  end
  
  before_filter :can_edit?, :only => %w(new create edit update destroy reorder)
  
  def new
    @family = Family.new
  end
  
  def create
    @family = Family.new_with_default_sharing(params[:family])
    respond_to do |format|
      if @family.save
        format.html { redirect_to @family }
        format.xml  { render :xml => @family, :status => :created, :location => @family }
        format.js
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @family.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  def edit
    @family = Family.find(params[:id])
  end

  def update
    @family = Family.find(params[:id])
    @family.update_attributes(params[:family])
    respond_to do |format|
      format.html { redirect_to @family }
      format.xml  { render :xml => @family.to_xml } if can_export?
    end
  end
  
  def destroy
    @family = Family.find(params[:id])
    if @family == @logged_in.family
      flash[:warning] = 'You cannot delete your own family.'
      redirect_to @family
    else
      @family.destroy
      redirect_to people_path
    end
  end
  
  def reorder
    @family = Family.find(params[:id])
    params[:people].to_a.each_with_index do |id, index|
      @family.people.find_by_id(id).update_attribute(:sequence, index+1)
    end
    render :nothing => true
  end
  
  def hashify
    if @logged_in.admin?(:import_data) and Site.current.import_export_enabled?
      if Family.connection.adapter_name == 'MySQL'
        hashes = Family.hashify(:legacy_ids => params[:hash][:legacy_id].to_s.split(','), :attributes => params[:hash][:attrs].split(','), :debug => params[:hash][:debug])
        render :xml => hashes
      else
        render :text => 'This method is only available in a MySQL environment.', :status => 500
      end
    else
      render :text => 'You are not authorized to import data.', :layout => true, :status => 401
    end
  end
  
  def batch
    if @logged_in.admin?(:import_data) and Site.current.import_export_enabled?
      records = Hash.from_xml(request.body.read)['records']
      statuses = records.map do |record|
        family = Family.find_by_legacy_id(record['legacy_id']) || Family.new
        record.each do |key, value|
          value = nil if value == ''
          family.write_attribute(key, value)
        end
        if family.save
          {:status => 'saved', :legacy_id => family.legacy_id, :id => family.id}
        else
          {:status => 'error', :legacy_id => record['legacy_id'], :error => family.errors.full_messages.join('; ')}
        end
      end
      render :xml => statuses
    else
      render :text => 'You are not authorized to import data.', :layout => true, :status => 401
    end
  end
  
  def select
    @family = Family.find(params[:id]) unless params[:id].blank?
    respond_to do |format|
      format.html { redirect_to new_person_path(:family_id => @family) }
      format.js
    end
  end

  def schema
    render :xml => Family.columns.map { |c| {:name => c.name, :type => c.type} }
  end
  
  private

  def can_edit?
    unless @logged_in.admin?(:edit_profiles)
      render :text => 'Not authorized or feature unavailable.', :layout => true, :status => 401
      return false
    end
  end
end
