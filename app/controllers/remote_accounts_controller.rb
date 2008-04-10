class RemoteAccountsController < ApplicationController
  before_filter :only_admins
  before_filter :get_remote_account, :except => [:index, :sync_person_options]
  verify :method => :post, :only => [:delete, :sync, :sync_person]
    
  def index
    @person = Person.find(params[:person_id])
    if @logged_in.can_edit? @person
      @remote_accounts = @person.remote_accounts
    else
      render :text => 'You are unauthorized.', :layout => true
    end
  end
  
  def edit
    unless @remote_account
      @remote_account = Person.find(params[:person_id]).remote_accounts.new
    end
    if request.post?
      if @remote_account.update_attributes(params[:remote_account])
        redirect_to remote_accounts_path(:person_id => @remote_account.person_id)
      else
        flash[:notice] = @remote_account.errors.full_messages.join('; ')
      end
    end
  end
  
  def delete
    @remote_account.destroy
    redirect_to remote_accounts_path(:person_id => @remote_account.person_id)
  end
  
  def sync
    @remote_account.update_all_remote_people
    flash[:notice] = 'Account synchronized.'
    redirect_to remote_accounts_path(:person_id => @remote_account.person_id)
  end
  
  def sync_person_options
    @person = Person.find(params[:id])
    @remote_accounts = @logged_in.remote_accounts.find(:all)
  end
  
  def sync_person
    @person = Person.find(params[:person_id])
    @remote_account.update_remote_person(@person)
    flash[:notice] = 'Person synchronized.'
    redirect_to person_path(:id => @person)
  end
  
  private
  
  def only_admins
    unless @logged_in.can_sync_remotely?
      render :text => 'You must be an administrator to use this section.', :layout => true
      return false
    end
  end
  
  def get_remote_account
    if params[:id]
      @remote_account = RemoteAccount.find_by_id(params[:id].to_i)
      unless @logged_in.can_edit? @remote_account
        render :text => 'You are not authorized to edit this account.', :layout => true
        return false
      end
    end
  end
end
