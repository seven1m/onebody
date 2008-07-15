class HelpsController < ApplicationController
  skip_before_filter :authenticate_user
  
  PAGES = %w(bad_status credits home_group index privacy_policy safeguarding_children unauthorized)
  
  def show
    page = params[:id] || 'index'
    if PAGES.include?(page)
      render :action => page
    else
      render :text => 'Page not found', :layout => true, :status => 404
    end
  end
  
end
