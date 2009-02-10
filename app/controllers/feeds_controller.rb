class FeedsController < ApplicationController

  skip_before_filter :authenticate_user
  before_filter :authenticate_user_with_code_or_session

  def show
    @person = @logged_in
    @items = @person.recently_tab_items
    respond_to do |format|
      format.html # show.html.erb
      format.js  { render :partial => 'feed' }
      format.xml { render :layout => false }
    end
  end

end
