class PusherController < ApplicationController
  protect_from_forgery except: :auth_printer

  def auth_printer
    if @logged_in && @logged_in.admin?(:manage_checkin) && (printer = session[:checkin_printer])
      response = Pusher[params[:channel_name]].authenticate(
        params[:socket_id],
        user_id: printer[:id],
        user_info: {
          user: {
            id: @logged_in.id,
            name: @logged_in.name
          },
          printer: {
            name: printer[:name]
          }
        }
      )
      render json: response
    else
      render text: I18n.t('not_authorized'), status: 403
    end
  end
end
