class Administration::Checkin::TimesController < ApplicationController

  before_filter :only_admins

  def index
    @recurring_times = CheckinTime.recurring
    @single_times = CheckinTime.upcoming_singles
  end

  def create
    @time = CheckinTime.create(time_params)
    add_errors_to_flash(@time) unless @time.valid?
    redirect_to administration_checkin_times_path
  end

  def edit
    redirect_to administration_checkin_time_groups_path(params[:id])
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
      render :text => 'You must be an administrator to use this section.', :layout => true, :status => 401
      return false
    end
  end

  def feature_enabled?
    unless Setting.get(:features, :checkin)
      render :text => 'This feature is unavailable.', :layout => true
      false
    end
  end

end
