class Administration::EmailSetupsController < ApplicationController
  before_filter :only_admins

  def show
    if OneBody.email_configured?
      @smtp_server = OneBody.smtp_config['address']
      @email_host = Site.current.email_host
    else
      redirect_to new_administration_email_setup_path
    end
  end

  def new
  end

  def create
    secret_api_key = params[:secret_api_key]
    if secret_api_key.present?
      session[:mailgun_key] = secret_api_key
      redirect_to action: :edit
    else
      redirect_to action: :new
    end
  end

  def edit
    if session[:mailgun_key]
      @domains = email_setup.domains
    else
      redirect_to action: :new
    end
  end

  def update
    if params[:domain].present?
      email_setup.domain = params[:domain]
      if email_setup.save!
        redirect_to action: :show, notice: t('administration.email_setups.edit.success')
      else
        redirect_to action: :edit, notice: t('administration.email_setups.edit.failure')
      end
    else
      redirect_to action: :edit
    end
  end

  private

  def email_setup
    @email_setup ||= EmailSetup.new(key: session[:mailgun_key], scheme: request.scheme)
  end

  def only_admins
    return if @logged_in.super_admin?
    render text: t('only_admins'), layout: true, status: 401
    false
  end
end
