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
  
  def create
    if Setting.get(:features, :standalone_use) and @logged_in.admin?(:edit_profiles)
      @family = Family.find(params[:family_id])
      @person = Person.new(:family => @family)
      params[:person].merge! :can_sign_in => true, :visible_to_everyone => true, :visible_on_printed_directory => true, :full_access => true
      unless @person.update_attributes(params[:person])
        flash[:warning] = @person.errors.full_messages.join('; ')
      end
      redirect_back
    end
  end

  def edit
    if @person = Person.find_by_id(params[:id]) and @logged_in.can_edit?(@person)
      @family = @person.family
      @service_categories = Person.service_categories
      @can_edit_basics = Setting.get(:features, :standalone_use) && @logged_in.admin?(:edit_profiles)
    else
      render :text => 'You are not authorized to edit this person.', :layout => true, :status => 401
    end
  end
  
  def update
    if @person = Person.find_by_id(params[:id]) and @logged_in.can_edit?(@person)
      @can_edit_basics = Setting.get(:features, :standalone_use) && @logged_in.admin?(:edit_profiles)
      if updated = @person.update_from_params(params, @can_edit_basics)
        flash[:refresh] = true if updated == 'photo'
        flash[:notice] = 'Changes saved.'
        redirect_to edit_person_path(@person, :anchor => params[:anchor])
      else
        render :text => @person.errors.full_messages.join('; '), :layout => true, :status => 500
      end
    else
      render :text => 'You are not authorized to edit this person.', :status => 401
    end
  end
  
  def destroy
    if Setting.get(:features, :standalone_use) and @logged_in.admin?(:edit_profiles)
      @person = Person.find(params[:id])
      unless @logged_in == @person
        family = @person.destroy.family
        redirect_to params[:return_to] || family_path(:id => family)
      else
        render :text => 'You cannot delete yourself.', :status => 500
      end
    else
     render :text => 'You are not authorized to delete this person.', :status => 401
    end
  end

end
