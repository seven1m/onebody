class FamiliesController < ApplicationController
  before_filter :get_family
  before_filter :check_standalone_and_admin, :only => [:view, :add_person, :delete_person]
  
  def photo
    if @logged_in.full_access?
      send_photo @family
    else
      render :text => 'unauthorized to view this photo', :status => 404
    end
  end
  
  def edit
    @family = Family.new unless params[:id]
    if request.post?
      if params[:family]
        check_standalone_and_admin
        params[:family][:home_phone] = params[:family][:home_phone].digits_only
        @family.update_attributes params[:family]
      else
        unless @logged_in.can_edit? @family
          render :text => 'You cannot edit this family photo.', :layout => true
          return false
        end
        if params[:photo_url] and params[:photo_url].length > 7
          @family.photo = params[:photo_url]
        elsif params[:photo]
          @family.photo = params[:photo] == 'remove' ? nil : params[:photo]
        end
        flash[:notice] = 'Photo saved.'
        flash[:refresh] = true
      end
      redirect_to params[:return_to] || (@logged_in.admin?(:edit_profiles) ? family_path(:id => @family) : edit_profile_path(:id => @logged_in))
    end
  end
  
  def view
  end
  
  def add_person
    @person = Person.new(:family => @family)
    params[:person].merge! :can_sign_in => true, :visible_to_everyone => true, :visible_on_printed_directory => true, :full_access => true
    if @person.update_attributes params[:person]
      redirect_to family_path(:id => @family)
    else
      flash[:warning] = @person.errors.full_messages.join('; ')
    end
  end
  
  private 
  
  def get_family
    @family = Family.find params[:id].to_i if params[:id]
  end
  
  def check_standalone_and_admin
    unless SETTINGS['features']['standalone_use'] and @logged_in.admin?(:edit_profiles)
      render :text => 'This feature is not available either because you are not an admin or Standalone Mode is off.', :layout => true
      return false
    end
  end
end
