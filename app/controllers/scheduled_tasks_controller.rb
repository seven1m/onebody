class ScheduledTasksController < ApplicationController

  before_filter :only_admins
  
  def index
    @tasks = Site.current.scheduled_tasks.find(:all, :conditions => ["interval != ?", 'now'])
  end
  
  def new
    @task = Site.current.scheduled_tasks.new
  end
  
  def create
    @task = Site.current.scheduled_tasks.create(params[:scheduled_task])
    unless @task.errors.any?
      flash[:notice] = 'Task saved.'
      redirect_to administration_scheduled_tasks_path
    else
      render :action => 'new'
    end
  end
  
  def edit
    @task = Site.current.scheduled_tasks.find(params[:id])
  end
  
  def update
    @task = Site.current.scheduled_tasks.find(params[:id])
    if @task.update_attributes(params[:scheduled_task])
      flash[:notice] = 'Task saved.'
      redirect_to administration_scheduled_tasks_path
    else
      render :action => 'edit'
    end
  end
  
  def destroy
    @task = Site.current.scheduled_tasks.find(params[:id])
    @task.destroy
    flash[:notice] = 'Task deleted.'
    redirect_to administration_scheduled_tasks_path
  end
  
  private
  
    def only_admins
      unless @logged_in.super_admin?
        render :text => 'You are not authorized.', :layout => true, :status => 401
        return false
      end
    end
  
end
