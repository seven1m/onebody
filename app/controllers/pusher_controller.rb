class PusherController < ApplicationController
  protect_from_forgery except: :auth_printer

  def auth_printer
    if printer
      response = Pusher[params[:channel_name]].authenticate(
        params[:socket_id],
        user_id: printer[:id],
        user_info: {
          user: {
            id: @checkin_logged_in.id,
            name: @checkin_logged_in.name
          },
          printer: printer
        }
      )
      render json: response
    elsif presence?
      response = Pusher[params[:channel_name]].authenticate(
        params[:socket_id],
        user_id: session.id,
        user_info: {
          ip: request.remote_ip
        }
      )
      render json: response
    else
      render json: { error: I18n.t('not_authorized') }, status: 403
    end
  end

  private

  def authenticate_user
    authenticate_user_for_checkin
  end

  def printer
    session[:checkin_logged_in_id].present? && session[:checkin_printer]
  end

  def presence?
    params[:channel_name] =~ /\Apresence-/
  end
end
