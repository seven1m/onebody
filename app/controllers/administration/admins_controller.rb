class Administration::AdminsController < ApplicationController
  before_filter :only_admins
  
  def index
    Admin.destroy_all(["(select count(*) from people where admin_id=admins.id and deleted=?) = 0 and template_name is null", false])
    @admin_count = Person.count('*', :conditions => ['admin_id is not null'])
    @templates = Admin.all(:order => 'template_name', :conditions => 'template_name is not null')
    @admins = @templates + Admin.all(:order => 'people.last_name, people.first_name', :include => :people, :conditions => 'template_name is null')
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
    flash[:notice] = ''
    params[:ids].to_a.each do |id|
      if Site.current.max_admins.nil? or Admin.count < Site.current.max_admins
        person = Person.find(id)
        if person.super_admin?
          flash[:notice] += "#{person.name} is a Super Administrator. "
        elsif person.admin?
          flash[:notice] += "#{person.name} is already an admin. "
        else
          person.admin = params[:template_id].to_i > 0 ? Admin.find(params[:template_id]) : Admin.create!
          person.save!
          if person.save
            flash[:notice] += "#{person.name} added. "
          else
            add_errors_to_flash(person)
          end
        end
      else
        flash[:notice] += 'No more admins are allowed.'
        break
      end
    end
    if params[:template_name]
      Admin.create!(:template_name => params[:template_name])
      flash[:notice] += 'Template created.'
    end
    redirect_to administration_admins_path
  end
  
  def destroy
    @admin = Admin.find(params[:id])
    if params[:person_id]
      Person.find(params[:person_id]).update_attribute(:admin_id, nil)
    else
      @admin.destroy
    end
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
