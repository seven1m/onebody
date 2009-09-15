class Administration::UpdatesController < ApplicationController
  before_filter :only_admins
  
  def index
    @updates = Update.paginate(
      :page       => params[:page],
      :conditions => ['complete = ?', params[:complete] == 'true'],
      :order      => 'created_at desc'
    )
    @unapproved_groups = Group.find_all_by_approved(false)
  end
  
  def update
    @update = Update.find(params[:id])
    if params[:complete] == 'true'
      if params[:update] and params[:update][:child]
        @update.child = (params[:update][:child] == 'true')
      elsif @update.birthday.nil?
        flash[:warning] = 'You must specify whether the person is a Child (under 13) or not to complete this update.'
        redirect_to administration_updates_path
        return
      end
      if @update.do!
        @update.update_attribute(:complete, true)
        if params[:review]
          redirect_to edit_person_path(@update.person, :anchor => 'basics')
        else
          redirect_to administration_updates_path
        end
      else
        render :action => 'error', :status => 500
      end
    else
      @update.update_attribute(:complete, false)
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
