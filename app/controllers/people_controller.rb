class PeopleController < ApplicationController

  caches_action :show, :for => 1.hour, :cache_path => Proc.new { |c| "people/#{c.params[:id]}_for_#{Person.logged_in.id}" }
  cache_sweeper :person_sweeper, :family_sweeper, :only => %w(create update destroy)

  def index
    respond_to do |format|
      format.html { redirect_to @logged_in }
      if @logged_in.admin?(:export_data)
        @people = Person.paginate(:order => 'last_name, first_name, suffix', :page => params[:page], :per_page => params[:per_page] || 50)
        format.xml { render :xml  => @people.to_xml(:except => %w(feed_code encrypted_password), :include => [:groups, :family]) }
        format.csv { render :text => @people.to_csv(:except => %w(feed_code encrypted_password), :include => [:family]) }
      end
    end
  end
  
  def show
    if @person = Person.find_by_id(params[:id], :include => :family) and @logged_in.can_see?(@person)
      @family = @person.family
      @family_people = @person.family.visible_people
      @me = (@logged_in == @person)
      @show_map = Setting.get(:services, :yahoo) and @person.family.mapable? and @person.share_address_wit(@logged_in)
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
      elsif params[:services]
        render :action => 'services'
      elsif not @logged_in.full_access? and not @me
        render :action => 'show_limited'
      end
    else
      render :text => 'Person not found.', :status => 404
    end
  end
  
  def new
    if @logged_in.admin?(:edit_profiles)
      @family = Family.find(params[:family_id])
      defaults = {:can_sign_in => true, :visible_to_everyone => true, :visible_on_printed_directory => true, :full_access => true}
      @person = Person.new(defaults.merge(:family_id => @family.id).merge(:last_name => @family.last_name))
    else
      render :text => 'You are not authorized to create a person.', :layout => true, :status => 401
    end
  end
  
  def create
    if @logged_in.admin?(:edit_profiles)
      @person = Person.create(params[:person])
      unless @person.errors.any?
        redirect_to @person.family
      else
        render :action => 'new'
      end
    else
      render :text => 'You are not authorized to create a person.', :layout => true, :status => 401
    end
  end

  def edit
    @person ||= Person.find(params[:id])
    if @logged_in.can_edit?(@person)
      @family = @person.family
      @service_categories = Person.service_categories
    else
      render :text => 'You are not authorized to edit this person.', :layout => true, :status => 401
    end
  end
  
  def update
    @person = Person.find(params[:id])
    if @logged_in.can_edit?(@person)
      if updated = @person.update_from_params(params)
        flash[:notice] = 'Changes saved.'
        redirect_to edit_person_path(@person, :anchor => params[:anchor])
      else
        edit; render :action => 'edit'
      end
    else
      render :text => 'You are not authorized to edit this person.', :layout => true, :status => 401
    end
  end
  
  def destroy
    if @logged_in.admin?(:edit_profiles)
      @person = Person.find(params[:id])
      unless me?
        @person.destroy
        redirect_to @person.family
      else
        render :text => 'You cannot delete yourself.', :status => 500
      end
    else
     render :text => 'You are not authorized to delete this person.', :status => 401
    end
  end
  
  def import
    if @logged_in.admin?(:import_data)
      if request.get?
        @column_names  = Person.columns.map { |c| c.name }
        @column_names += Family.columns.map { |c| "family_#{c.name}" }
        @column_names.reject! { |c| c =~ /site_id/ }
      elsif request.post?
        @records = Person.queue_import_from_csv_file(params[:file].read, params[:match_by_name])
        render :action => 'import_queue'
      elsif request.put?
        Person.import_data(params)
        render :text => 'Import successful.', :layout => true
      end
    else
      render :text => 'You are not authorized to import data.', :layout => true, :status => 401
    end
  end

end
