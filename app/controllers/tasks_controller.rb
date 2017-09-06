class TasksController < ApplicationController
  load_and_authorize_parent :group, optional: true
  load_and_authorize_resource

  def index
    if !@group
      @groups = @logged_in.tasks.map(&:group).uniq
    elsif @logged_in.member_of?(@group)
      @tasks = tasks.order(completed: :asc, duedate: :asc).page(params[:page])
    else
      render plain: t('not_authorized'), layout: true, status: :forbidden
    end
  end

  def show
  end

  def new
  end

  def create
    if @task.save
      redirect_to group_tasks_path(@group)
    else
      render action: 'new'
    end
  end

  def edit
  end

  def update
    if @task.update_attributes(task_params)
      redirect_to group_task_path(@group, @task)
    else
      render action: 'edit'
    end
  end

  def destroy
    @task = Task.find(params[:id])
    if @logged_in.can_delete?(@task)
      @task.destroy
      flash[:notice] = t('tasks.deleted')
      redirect_back
    else
      render plain: t('not_authorized'), layout: true, status: 401
    end
  end

  def complete
    @task = @group.tasks.find(params[:id])
    @task.update_attribute(:completed, params[:task][:completed])
    head :ok
  end

  def update_position
    @task = Task.find(params[:id])
    @task.insert_at(params[:position].to_i) if @task.updatable_by?(@logged_in)
    head :ok
  end

  private

  def task_params
    params.require(:task).permit(:person_id, :person_id_or_all, :name, :description, :duedate, :group_id)
  end
end
