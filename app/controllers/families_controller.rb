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
    @family = params[:id] ? Family.find(params[:id]) : @logged_in.family
    unless @logged_in.can_edit? @family.people.first
      render :text => 'Sorry. You may not change this family photo because you are not an adult according to our records. (If we're wrong, let us know!)', :layout => true
      return
    if request.post?
      if params[:photo_url] and params[:photo_url].length > 7
        @family.photo = params[:photo_url]
      elsif params[:photo]
        @family.photo = params[:photo] == 'remove' ? nil : params[:photo]
      end
      flash[:notice] = 'Photo saved.'
    end
    redirect_to params[:return_to] || {:controller => 'people', :action => 'edit'}
  end
end
