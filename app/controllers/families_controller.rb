class FamiliesController < ApplicationController
  
  cache_sweeper :person_sweeper, :family_sweeper, :only => %w(create update destroy)
  
  def index
    respond_to do |format|
      format.html { redirect_to @logged_in }
      if can_export?
        @families = Family.paginate(:order => 'last_name, name', :page => params[:page], :per_page => params[:per_page] || MAX_EXPORT_AT_A_TIME)
        format.xml do
          if @families.any?
            render :xml  => @families.to_xml(:include => [:people], :except => %w(site_id))
          else
            flash[:warning] = 'No more records.'
            redirect_to people_path
          end
        end
        format.csv do
          if @families.any?
            render :text => @families.to_csv(:except => %w(site_id))
          else
            flash[:warning] = 'No more records.'
            redirect_to people_path
          end
        end
      end
    end
  end
  
  def show
    if params[:legacy_id]
      @family = Family.find_by_legacy_id(params[:id])
    elsif params[:barcode_id]
      @family = Family.find_by_barcode_id_and_deleted(params[:id], false)
    else
      @family = Family.find_by_id(params[:id])
    end
    raise ActiveRecord::RecordNotFound unless @family
    @people = @family.people.all.select { |p| @logged_in.can_see? p }
    if @logged_in.can_see?(@family)
      respond_to do |format|
        format.html
        format.xml  { render :xml => @family.to_xml } if can_export?
        format.json { render :text => @family.to_json(:except => %w(site_id)) } if can_export?
        format.js do
          if params[:barcode_entry]
            render :update do |page|
              page.replace_html 'family', :partial => 'details'
              page.replace_html 'barcode', :partial => 'barcode_entry'
              page << "$('family_barcode_id').focus(); $('family_barcode_id').select();"
            end
          end
        end
      end
    else
      render :text => 'Family not found.', :status => 404
    end
  end
  
  before_filter :can_edit?, :only => %w(new create edit update destroy reorder)
  
  def new
    @family = Family.new
    25.times { @family.people.build }
  end
  
  def create
    if params[:family][:people_attributes]
      params[:family][:people_attributes].reject! do |num, person|
        person[:first_name].blank? || person[:birthday].blank?
      end
    end
    @family = Family.new_with_default_sharing(params[:family])
    respond_to do |format|
      if @family.save
        format.html do
          if params[:barcode]
            render :text => "Family saved. Assigned number: #{@family.barcode_id}<br/><a href=\"#{administration_checkin_path}\">Click here</a> to return...", :layout => true
          else
            redirect_to params[:redirect_to] || @family
          end
        end
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
    if @family.update_attributes(params[:family])
      respond_to do |format|
        format.html { flash[:notice] = 'Family saved.'; redirect_to params[:redirect_to] || @family }
        format.xml  { render :xml => @family.to_xml } if can_export?
        format.js do # only used by barcode entry right now
          render :update do |page|
            page.replace_html :notice, "Family saved. Assigned number: #{@family.barcode_id}"
            page[:notice].show
          end
        end
      end
    else
      respond_to do |format|
        format.html { flash[:warning] = 'There were errors.'; redirect_to params[:redirect_to] || @family }
        format.xml  { render :xml => @family.errors, :status => :unprocessable_entity } if can_export?
        format.js do # only used by barcode entry right now
          render :update do |page|
            page.replace_html :notice, "There were errors:<br/>#{@family.errors.full_messages.join('; ')}"
            page[:notice].show
          end
        end
      end
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
      p = @family.people.find_by_id(id)
      p.no_auto_sequence = true
      p.update_attribute(:sequence, index+1)
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
          if key == 'barcode_id' and family.barcode_id_changed?
            if value == family.barcode_id
              family.write_attribute(:barcode_id_changed, false)
            else
              next
            end
          end
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
