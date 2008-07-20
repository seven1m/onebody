class PeopleController < ApplicationController

  caches_action :show, :for => 1.hour, :cache_path => Proc.new { |c| "people/#{c.params[:id]}_for_#{Person.logged_in.id}" }
  cache_sweeper :person_sweeper, :family_sweeper, :only => %w(create update destroy)

  def index
    redirect_to @logged_in
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

end
