class EmailsController < ApplicationController
  skip_before_action :authenticate_user, only: :create
  before_action :ensure_admin, except: %w(create)
  skip_before_action :verify_authenticity_token

  def create
    Notifier.receive(params['body-mime'])
    head :created
  end

  private

  def ensure_admin
    return if @logged_in.super_admin?
    render html: t('not_authorized'), layout: true
    false
  end
end
