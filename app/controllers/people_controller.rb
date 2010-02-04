class PeopleController < ApplicationController

  caches_action :show, :for => 15.minutes, :cache_path => Proc.new { |c| "people/#{c.params[:id]}#{c.params[:simple] ? '_simple' : ''}#{c.params[:business] ? '_business' : ''}_for_#{Person.logged_in.id}" }, :if => Proc.new { |c| c.params[:format] != 'iphone' }
  cache_sweeper :person_sweeper, :family_sweeper, :only => %w(create update destroy import batch)
  
  def index
    respond_to do |format|
      format.html { redirect_to person_path(@logged_in, :tour => params[:tour]) }
      if can_export?
        if params[:family_id]
          @people = Person.find_all_by_family_id_and_deleted(params[:family_id], false)
          @people.reject! { |p| p.at_least?(18) } if params[:child]
        else
          @people = Person.paginate(:conditions => ['deleted = ?', false], :order => 'last_name, first_name, suffix', :page => params[:page], :per_page => params[:per_page] || MAX_EXPORT_AT_A_TIME)
        end
        format.xml do
          if @people.any?
            render :xml  => @people.to_xml(:read_attribute => true, :except => %w(feed_code encrypted_password salt api_key site_id), :include => [:groups, :family])
          else
            flash[:warning] = 'No more records.'
            redirect_to people_path
          end
        end
        format.csv do
          if @people.any?
            render :text => @people.to_csv_mine(:read_attribute => true, :except => %w(feed_code encrypted_password salt api_key site_id), :include => params[:no_family] ? nil : [:family], :methods => %w(group_names))
          else
            flash[:warning] = 'No more records.'
            redirect_to people_path
          end
        end
        format.json do
          if @people.any?
            render :text => @people.to_json(:read_attribute => true, :except => %w(feed_code encrypted_password salt api_key site_id), :include => params[:no_family] ? nil : [:family])
          else
            flash[:warning] = 'No more records.'
            redirect_to people_path
          end
        end
      end
    end
  end
  
  def show
    if params[:id].to_i == session[:logged_in_id]
      @person = @logged_in
    elsif params[:legacy_id]
      @person = Person.find_by_legacy_id(params[:id], :include => :family)
    else
      @person = Person.find_by_id(params[:id], :include => :family)
    end
    if @person and @logged_in.can_see?(@person)
      @family = @person.family
      @family_people = @person.family.visible_people
      #@show_map = Setting.get(:services, :yahoo) and @person.family.mapable? and @person.share_address_with(@logged_in)
      @friends = @person.friends.all(:limit => MAX_FRIENDS_ON_PROFILE, :order => 'friendships.ordering').select { |p| @logged_in.can_see?(p) }
      @sidebar_group_people = @person.random_sidebar_group_people.select { |p| @logged_in.can_see?(p) }
      @stream_items = @person.shared_stream_items(20, :mine)
      @albums = @person.albums.all(:order => 'created_at desc')
      if params[:simple]
        if @logged_in.full_access?
          if params[:photo]
            render :action => 'show_simple_photo', :layout => false
          else
            render :action => 'show_simple', :layout => false
          end
        else
          render :text => '', :status => 404
        end
      elsif params[:business]
        render :action => 'business'
      elsif not @logged_in.full_access? and not @me
        render :action => 'show_limited'
      else
        respond_to do |format|
          format.html
          format.iphone
          format.xml { render :xml => @person.to_xml(:read_attribute => true) } if can_export?
        end
      end
    elsif @person and @person.deleted? and @logged_in.admin?(:edit_profiles)
      render :text => "This person has been deleted. You can restore the record <a href=\"#{administration_deleted_people_path('search[id]' => @person.id)}\">here</a>.", :status => 404, :layout => true
    else
      render :text => 'Person not found.', :status => 404, :layout => true
    end
  end
  
  def new
    if Person.can_create?
      if @logged_in.admin?(:edit_profiles)
        defaults = {:can_sign_in => true, :visible_to_everyone => true, :visible_on_printed_directory => true, :full_access => true}
        unless params[:family_id].nil?
          @family = Family.find(params[:family_id])
          number = @family.people.count('*', :conditions => ['deleted = ?', false])
          @person = Person.new(defaults.merge(:family_id => @family.id).merge(:last_name => @family.last_name))
        else
          @family_option = "new_family"
          @family = Family.new
          number = 0
          @person = Person.new(defaults)
        end
        @person.child = (number >= 2)
      else
        render :text => I18n.t('not_authorized'), :layout => true, :status => 401
      end
      respond_to do |format|
        format.html if !@family.new_record?
        format.html { render :partial => "new_family", :layout => true } if @family.new_record?
      end
    else
      render :text => 'No people can be added at this time.', :layout => true, :status => 401
    end
  end
  
  def create
    if Person.can_create?
      if @logged_in.admin?(:edit_profiles)
        params[:person].cleanse(:birthday, :anniversary)
        @person = Person.new(params[:person])
        respond_to do |format|
          if @person.save
            format.html { redirect_to @person.family }
            format.xml  { render :xml => @person, :status => :created, :location => @person }
          else
            format.html { render :action => "new" }
            format.xml  { render :xml => @person.errors, :status => :unprocessable_entity }
          end
        end
      else
        render :text => I18n.t('not_authorized'), :layout => true, :status => 401
      end
    else
      render :text => 'No people can be added at this time.', :layout => true, :status => 401
    end
  end

  def edit
    @person ||= Person.find(params[:id])
    if @logged_in.can_edit?(@person)
      @family = @person.family
      @business_categories = Person.business_categories
      @custom_types = Person.custom_types
    else
      render :text => I18n.t('not_authorized'), :layout => true, :status => 401
    end
  end
  
  def update
    @person = Person.find(params[:id])
    if @logged_in.can_edit?(@person)
      if updated = @person.update_from_params(params)
        respond_to do |format|
          format.html do
            flash[:notice] = 'Changes submitted.'
            redirect_to edit_person_path(@person, :anchor => params[:anchor])
          end
          format.xml { render :xml => @person.to_xml } if can_export?
        end
      else
        edit; render :action => 'edit'
      end
    else
      render :text => I18n.t('not_authorized'), :layout => true, :status => 401
    end
  end
  
  def destroy
    if @logged_in.admin?(:edit_profiles)
      @person = Person.find(params[:id])
      if me?
        render :text => 'You cannot delete yourself.', :layout => true, :status => 401
      elsif @person.global_super_admin?
        render :text => 'You cannot delete this person.', :layout => true, :status => 401
      else
        @person.destroy
        redirect_to @person.family
      end
    else
     render :text => I18n.t('not_authorized'), :layout => true, :status => 401
    end
  end
  
  def import
    if @logged_in.admin?(:import_data) and Site.current.import_export_enabled?
      if request.get?
        @column_names = Person.importable_column_names
      elsif request.post?
        @records = Person.queue_import_from_csv_file(params[:file].read, params[:match_by_name], params[:attributes])
        render :action => 'import_queue'
      elsif request.put?
        @completed, @errored = Person.import_data(params)
        render :action => 'import_results'
      end
    else
      render :text => I18n.t('not_authorized'), :layout => true, :status => 401
    end
  end
  
  def hashify
    if @logged_in.admin?(:import_data) and Site.current.import_export_enabled?
      if Person.connection.adapter_name == 'MySQL'
        ids = params[:hash][:legacy_id].to_s.split(',')
        raise 'Too many at once' if ids.length > 1000
        hashes = Person.hashify(:legacy_ids => ids, :attributes => params[:hash][:attrs].split(','), :debug => params[:hash][:debug])
        render :xml => hashes
      else
        render :text => 'This method is only available in a MySQL environment.', :status => 500
      end
    else
      render :text => I18n.t('not_authorized'), :layout => true, :status => 401
    end
  end
  
  def batch
    # post from families/show page
    if params[:family_id] and @logged_in.admin?(:edit_profiles)
      params[:ids].each { |id| Person.find(id).update_attribute(:family_id, params[:family_id]) }
      respond_to do |format|
        format.html { redirect_to family_path(params[:family_id]) }
        format.js   { render(:update) { |p| p.redirect_to family_path(params[:family_id]) } }
      end
    # API for use by UpdateAgent
    elsif @logged_in.admin?(:import_data) and Site.current.import_export_enabled?
      xml_params = Hash.from_xml(request.body.read)['hash']
      statuses = Person.update_batch(xml_params['records'], xml_params['options'] || {})
      respond_to do |format|
        format.xml { render :xml => statuses }
      end
    else
      render :text => I18n.t('not_authorized'), :layout => true, :status => 401
    end
  end
  
  def schema
    render :xml => Person.columns.map { |c| {:name => c.name, :type => c.type} }
  end
  
  def favs
    @person = Person.find(params[:id])
    unless @logged_in.can_see?(@person)
      render :text => 'Person not found.', :status => 404, :layout => true
    end
  end
  
  def testimony
    @person = Person.find(params[:id])
    unless @logged_in.can_see?(@person)
      render :text => 'Person not found.', :status => 404, :layout => true
    end
  end

end
