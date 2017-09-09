class Checkin::PrintersController < ApplicationController
  layout 'checkin_printer'

  def show
    @printer = if (name = cookies[:checkin_printer_name]).present?
                 session[:checkin_printer] = {
                   id:   name.gsub(/[^a-z0-9]/i, '_').downcase,
                   name: name
                 }
               else
                 {}
               end
  end

  def update
    cookies[:checkin_printer_name] = {
      value: params[:printer_name],
      expires: 100.years.from_now
    }
    redirect_to action: :show
  end

  private

  def authenticate_user
    authenticate_user_for_checkin
  end

  def feature_enabled?
    return if Setting.get(:features, :checkin)
    render html: I18n.t('feature_unavailable'), layout: true
    false
  end
end
