class Checkin::InterfacesController < ApplicationController

  skip_before_filter :authenticate_user
  layout 'checkin'

  def show
    if params[:select]
      render action: 'select'
    end
  end

end
