class Administration::CheckinDashboardsController < ApplicationController

  before_filter :only_admins
  
  def show
  end
  
end
