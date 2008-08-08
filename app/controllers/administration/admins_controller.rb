class Administration::AdminsController < ApplicationController
  before_filter :only_admins
  
  def update
    @admin = Admin.find(params[:id])
    @admin.update_attribute(params[:name], params[:value])
  end
  
  def create
    params[:ids].to_a.each do |id|
      if Site.current.max_admins.nil? or Admin.count < Site.current.max_admins
        person = Person.find(id)
        if person.super_admin?
          flash[:notice] = "#{person.name} is a Super Administrator."
        else
          person.admin = Admin.create!
          add_errors_to_flash(person) unless person.save
        end
      else
        flash[:notice] = 'No more admins are allowed.'
      end
    end
    redirect_to admin_path
  end
  
  def destroy
    @admin = Admin.find(params[:id])
    @admin.destroy
    redirect_to admin_path
  end
  
  private
  
    def only_admins
      unless @logged_in.admin?(:manage_access)
        render :text => 'You must be an administrator to use this section.', :layout => true, :status => 401
        return false
      end
    end

end
