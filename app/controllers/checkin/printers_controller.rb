class Checkin::PrintersController < ApplicationController
  before_action :only_admins

  layout 'checkin_printer'

  def show
    if (name = cookies[:checkin_printer_name]).present?
      @printer = session[:checkin_printer] = {
        id:   name.gsub(/[^a-z0-9]/i, '_').downcase,
        name: name
      }
    else
      @printer = {}
    end
  end

  def update
    cookies[:checkin_printer_name] = {
      value: params[:printer_name],
      expires: 1.year.from_now
    }
    redirect_to action: :show
  end

  private

  def only_admins
    return if @logged_in.admin?(:manage_checkin)
    render text: I18n.t('only_admins'), layout: true, status: 401
    false
  end

  def feature_enabled?
    return if Setting.get(:features, :checkin)
    render text: I18n.t('feature_unavailable'), layout: true
    false
  end
end
