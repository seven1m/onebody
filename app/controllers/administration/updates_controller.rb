class Administration::UpdatesController < ApplicationController
  before_filter :only_admins
  
  def index
    @updates = Update.find_all_by_complete(params[:complete] == 'true')
    @unapproved_groups = Group.find_all_by_approved(false)
  end
  
  def update
    @update = Update.find(params[:id])
    @update.toggle! :complete
    if @update.complete and params[:update]
      if @update.do!
        if params[:review]
          redirect_to edit_person_path(@update.person, :anchor => 'basics')
        else
          redirect_to administration_updates_path
        end
      else
        add_errors_to_flash(@update)
        index; render :action => 'index'
      end
    else
      redirect_to administration_updates_path
    end
  end

  def destroy
    @update = Update.find(params[:id])
    @update.destroy
    redirect_to administration_updates_path
  end
  
  private
  
    def only_admins
      unless @logged_in.admin?(:manage_updates)
        render :text => 'You must be an administrator to use this section.', :layout => true, :status => 401
        return false
      end
    end

end
