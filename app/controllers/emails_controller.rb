class EmailsController < ApplicationController

  skip_before_filter :authenticate_user, only: :create
  before_action :ensure_admin, except: %w(create)

  def create
    Notifier.receive(params['body-mime'])
    render nothing: true
  end

  def create_route
    result = Email.create_catch_all
    if result['message'] == 'Route found.'
      flash[:notice] = t('application.mailgun_route_found')
    elsif result['message'] == 'Route has been created'
      flash[:notice] = t('application.mailgun_route_created')
    elsif result['message'] == 'apikey'
      flash[:notice] = t('application.mailgun_apikey_notfound')
    else
      flash[:error] = t('application.mailgun_route_error')
    end
    redirect_to administration_settings_path(anchor: 'tab-advanced')
  end

  private

  def ensure_admin
    unless @logged_in.super_admin?
      render text: t('not_authorized'), layout: true
      false
    end
  end


end
