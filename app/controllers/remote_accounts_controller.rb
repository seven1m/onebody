class RemoteAccountsController < ApplicationController
  before_filter :only_admins
  
  def index
    @person = Person.find(params[:person_id])
    if @logged_in.can_edit?(@person)
      @remote_accounts = @person.remote_accounts.all
    else
      render :text => 'Not found.', :layout => true, :status => 404
    end
  end
  
  def new
    @person = Person.find(params[:person_id])
    if @logged_in.can_edit?(@person)
      @remote_account = @person.remote_accounts.new
    else
      render :text => I18n.t('not_authorized'), :layout => true, :status => 401
    end
  end
  
  def create
    @person = Person.find(params[:person_id])
    if @logged_in.can_edit?(@person)
      @remote_account = @person.remote_accounts.create(params[:remote_account])
      unless @remote_account.errors.any?
        redirect_to person_remote_accounts_path(@person)
      else
        new; render :action => 'new'
      end
    else
      render :text => I18n.t('not_authorized'), :layout => true, :status => 401
    end
  end
  
  def edit
    @person = Person.find(params[:person_id])
    if @logged_in.can_edit?(@person)
      @remote_account = @person.remote_accounts.find(params[:id])
    else
      render :text => I18n.t('not_authorized'), :layout => true, :status => 401
    end
  end
  
  def update
    @person = Person.find(params[:person_id])
    if @logged_in.can_edit?(@person)
      @remote_account = @person.remote_accounts.find(params[:id])
      if @remote_account.update_attributes(params[:remote_account])
        redirect_to person_remote_accounts_path(@person)
      else
        edit; render :action => 'edit'
      end
    else
      render :text => I18n.t('not_authorized'), :layout => true, :status => 401
    end
  end
  
  def destroy
    @person = Person.find(params[:person_id])
    if @logged_in.can_edit?(@person)
      @remote_account = @person.remote_accounts.find(params[:id])
      @remote_account.destroy
      redirect_to person_remote_accounts_path(@person)
    else
      render :text => I18n.t('not_authorized'), :layout => true, :status => 401
    end
  end
  
  def sync
    @person = Person.find(params[:person_id])
    if @logged_in.can_edit?(@person)
      @remote_account = @person.remote_accounts.find(params[:id])
      @remote_account.update_all_remote_people
      flash[:notice] = 'Account synchronized.'
      redirect_to person_remote_accounts_path(@person)
    else
      render :text => I18n.t('not_authorized'), :layout => true, :status => 401
    end
  end
  
  private
  
  def only_admins
    unless @logged_in.can_sync_remotely?
      render :text => I18n.t('only_admins'), :layout => true, :status => 401
      return false
    end
  end
  
end
