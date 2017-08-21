class Administration::EmailsController < ApplicationController
  before_action :only_admins

  def index
    @people = Person.where(email_changed: true, deleted: false).order('last_name, first_name')
  end

  def batch
    params[:ids].to_a.each do |id|
      Person.find(id).update_attribute(:email_changed, false)
    end
    flash[:notice] = t('messages.flag_cleared')
    redirect_to administration_emails_path
  end

  private

  def only_admins
    unless @logged_in.admin?(:manage_updates)
      render plain: t('only_admins'), layout: true, status: 401
      false
    end
  end
end
