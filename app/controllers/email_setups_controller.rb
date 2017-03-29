class EmailSetupsController < ApplicationController
  before_filter :only_admins

  def show
    redirect_to edit_email_setup_path
  end

  def edit
  end

  private

  def only_admins
    return if @logged_in.super_admin?
    render text: t('only_admins'), layout: true, status: 401
    return false
  end
end
