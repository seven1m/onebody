class Administration::Checkin::TimesController < ApplicationController
  before_filter :only_admins

  def index
    @recurring_times = CheckinTime.recurring.order(:weekday, :time)
    @single_times = CheckinTime.future_singles.order(:the_datetime)
  end

  def show
    redirect_to administration_checkin_time_groups_path(params[:id])
  end

  def edit
    @time = CheckinTime.find(params[:id])
  end

  def create
    @time = CheckinTime.create(time_params)
    add_errors_to_flash(@time) unless @time.valid?
    redirect_to administration_checkin_times_path
  end

  def update
    @time = CheckinTime.find(params[:id])
    if @time.update_attributes(time_params)
      flash[:notice] = t('changes_saved')
    else
      add_errors_to_flash(@time)
    end
    redirect_to administration_checkin_times_path
  end

  def destroy
    @time = CheckinTime.find(params[:id])
    @time.destroy
    redirect_to administration_checkin_times_path
  end

  private

  def time_params
    params.require(:checkin_time).permit(:weekday, :time, :the_datetime, :campus)
  end

  def only_admins
    unless @logged_in.admin?(:manage_checkin)
      render plain: 'You must be an administrator to use this section.', layout: true, status: 401
      false
    end
  end

  def feature_enabled?
    unless Setting.get(:features, :checkin)
      render plain: 'This feature is unavailable.', layout: true
      false
    end
  end
end
