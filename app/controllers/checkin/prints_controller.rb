class Checkin::PrintsController < ApplicationController
  skip_before_action :authenticate_user

  def create
    if session[:checkin_printer_id]
      Pusher.trigger(
        "private-prints-#{session[:checkin_printer_id]}",
        'print',
        params[:print]
      )
      render json: { status: 'sent' }, status: 201
    else
      render json: { error: 'no printer selected' }, status: 400
    end
  end

  private

  def feature_enabled?
    return if Setting.get(:features, :checkin)
    render html: I18n.t('feature_unavailable'), layout: true
    false
  end
end
