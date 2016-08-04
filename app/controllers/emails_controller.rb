class EmailsController < ApplicationController
  skip_before_action :authenticate_user, only: :create
  before_action :ensure_admin, except: %w(create)
  skip_before_action :verify_authenticity_token

  def create
    Notifier.receive(params['body-mime'])
    render nothing: true
  end

  def create_route
    return if request.get?
    begin
      MailgunApi.new(params[:api_key]).create_catch_all
    rescue MailgunApi::KeyMissing
      flash[:error] = t('emails.mailgun.apikey_notfound')
    rescue MailgunApi::Forbidden
      flash[:error] = t('emails.mailgun.route_error')
    rescue MailgunApi::RouteAlreadyExists
      flash[:notice] = t('emails.mailgun.route_found')
      redirect_to admin_path
    else
      flash[:notice] = t('emails.mailgun.route_created')
      redirect_to admin_path
    end
  end

  private

  def ensure_admin
    return if @logged_in.super_admin?
    render text: t('not_authorized'), layout: true
    false
  end
end
