class FamiliesController < ApplicationController
  def photo
    @family = Family.find params[:id].to_i
    if @logged_in.member?
      send_photo @family
    else
      render :text => 'unauthorized to view this photo', :status => 404
    end
  end
  
  def edit
    @family = @logged_in.family
    if request.post?
      if params[:photo_url] and params[:photo_url].length > 7
        @family.photo = params[:photo_url]
      elsif params[:photo]
        @family.photo = params[:photo] == 'remove' ? nil : params[:photo]
      end
      flash[:notice] = 'Photo saved.'
    end
    redirect_to :controller => 'people', :action => 'edit'
  end
end
