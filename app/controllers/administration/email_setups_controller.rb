class Administration::EmailSetupsController < ApplicationController
  before_filter :only_admins

  def show
    redirect_to new_administration_email_setup_path
  end

  def new
  end

  def edit
    if session[:mailgun]
      @domains = EmailSetup.new(session[:mailgun][:secret_api_key]).domains
    else
      redirect_to action: :new
    end
  end

  def create
    secret_api_key = params[:secret_api_key]
    if secret_api_key.present?
      session[:mailgun] = {
        secret_api_key: secret_api_key
      }
      redirect_to action: :edit
    else
      redirect_to action: :new
    end
  end

  private

  def only_admins
    return if @logged_in.super_admin?
    render text: t('only_admins'), layout: true, status: 401
    return false
  end
end
