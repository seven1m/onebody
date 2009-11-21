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
      @family = Family.find_by_barcode_id_and_deleted(params[:id], false) ||
        Family.find_by_alternate_barcode_id_and_deleted(params[:id], false)
    else
      @family = Family.find_by_id_and_deleted(params[:id], false)
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
  end
  
  def create
    @family = Family.new_with_default_sharing(params[:family])
    respond_to do |format|
      if @family.save
        format.html do
          redirect_to params[:redirect_to] || @family
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
    if @logged_in.admin?(:edit_profiles) and params[:delete]
      params[:ids].to_a.each do |id|
        Family.find(id).destroy
      end
      redirect_back
    elsif @logged_in.admin?(:import_data) and Site.current.import_export_enabled?
      xml_params = Hash.from_xml(request.body.read)['hash']
      options = xml_params['options'] || {}
      records = xml_params['records']
      statuses = records.map do |record|
        family = Family.find_by_legacy_id(record['legacy_id'])
        if family.nil? and options['claim_families_by_barcode_if_no_legacy_id'] and record['barcode_id'].to_s.any?
          family = Family.find_by_legacy_id_and_barcode_id(nil, record['barcode_id'])
        end
        family ||= Family.new
        if options['delete_families_with_conflicting_barcodes_if_no_legacy_id'] and !family.new_record?
          Family.destroy_all ["legacy_id is null and barcode_id = ? and id != ?", record['barcode_id'], family.id]
        end
        record.each do |key, value|
          value = nil if value == ''
          if key == 'barcode_id' and family.barcode_id_changed?
            if value == family.barcode_id
              family.write_attribute(:barcode_id_changed, false)
            else
              next
            end
          elsif %w(barcode_id_changed remote_hash).include?(key)
            next
          end
          family.write_attribute(key, value)
        end
        family.dont_mark_barcode_id_changed = true
        if family.save
          s = {:status => 'saved', :legacy_id => family.legacy_id, :id => family.id, :name => family.name}
          if family.barcode_id_changed?
            s[:status] = 'saved with error'
            s[:error] = "Newer barcode not overwritten: #{family.barcode_id.inspect}"
          end
          s
        else
          {:status => 'not saved', :legacy_id => record['legacy_id'], :id => family.id, :name => family.name, :error => family.errors.full_messages.join('; ')}
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
