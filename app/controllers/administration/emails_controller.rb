class Administration::EmailsController < ApplicationController
  before_filter :only_admins
  
  def index
    @people = Person.find_all_by_email_changed_and_deleted(true, false, :order => 'last_name, first_name')
  end
  
  def batch
    params[:ids].to_a.each do |id|
      Person.find(id).update_attribute(:email_changed, false)
    end
    flash[:notice] = 'Flag(s) cleared.'
    redirect_to administration_emails_path
  end
  
  private
  
    def only_admins
      unless @logged_in.admin?(:manage_updates)
        render :text => I18n.t('only_admins'), :layout => true, :status => 401
        return false
      end
    end

end
