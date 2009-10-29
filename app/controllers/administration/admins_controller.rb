class Administration::AdminsController < ApplicationController
  before_filter :only_admins
  
  def index
    Admin.destroy_all(["(select count(*) from people where admin_id=admins.id and deleted=?) = 0", false])
    @admin_groups = Admin.all(:conditions => "template_name is not null")
    @admins = Admin.all(:order => 'people.last_name, people.first_name', :include => :people)
  end
  
  def update
    @admin = Admin.find(params[:id])
    @privs = params[:name] == '*' ? Admin.privileges : [params[:name]]
    @privs.each do |priv|
      @admin.flags[priv] = params[:value] == 'true'
    end
    @success = @admin.save
  end
  
  def create
    params[:ids].to_a.each do |id|
      if Site.current.max_admins.nil? or Admin.count < Site.current.max_admins
        person = Person.find(id)
        if person.super_admin?
          flash[:notice] = "#{person.name} is a Super Administrator."
        else
          person.admin = Admin.create!
          if person.save
            flash[:notice] = 'Admin created.'
          else
            add_errors_to_flash(person)
          end
        end
      else
        flash[:notice] = 'No more admins are allowed.'
      end
    end
    redirect_to administration_admins_path
  end
  
  def destroy
    @admin = Admin.find(params[:id])
    @admin.destroy
    flash[:notice] = 'Admin removed.'
    redirect_to administration_admins_path
  end
  
  private
  
    def only_admins
      unless @logged_in.admin?(:manage_access)
        render :text => 'You must be an administrator to use this section.', :layout => true, :status => 401
        return false
      end
    end

end
