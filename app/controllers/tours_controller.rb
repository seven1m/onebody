class ToursController < ApplicationController

  # allow start/stop from a get request
  def show
    if params[:start]
      create
    elsif params[:stop]
      destroy
    else
      raise ActionController::UnknownAction, 'No action responded to show'
    end
  end

  def create
    session[:touring] = true
    redirect_to stream_path
  end
  
  def destroy
    session[:touring] = false
    redirect_back
  end

end
