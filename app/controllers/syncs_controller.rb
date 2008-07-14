class SyncsController < ApplicationController

  def show
    @person = Person.find(params[:person_id])
    @remote_accounts = @logged_in.remote_accounts.all
  end
  
  def update
    @person = Person.find(params[:person_id])
    @remote_account = @logged_in.remote_accounts.find(params[:remote_account_id])
    @remote_account.update_remote_person(@person)
    flash[:notice] = 'Person synchronized.'
    redirect_to @person
  end

end
