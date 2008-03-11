class NametagsController < ApplicationController
  before_filter :check_access
  
  def index
    @selected = session[:nametag_selections].to_a
  end
  
  def add
    session[:nametag_selections] ||= []
    if @person = Person.find(params[:id]) \
      and not session[:nametag_selections].include? @person
      session[:nametag_selections] << @person
    end
    respond_to do |format|
      format.js
    end
  end
  
  def remove
    if @person = Person.find(params[:id])
      session[:nametag_selections].delete @person
    end
    redirect_to nametags_url
  end
  
  def print
    @selected = session[:nametag_selections].to_a.sort_by &:name
  end
  
  def barcode
    @person = Person.find(params[:id])
    if @person.barcode_id
      code = '0' + code while (code = @person.barcode_id).length < 3
      image = BarcodeGenerator.get_barcode_image(code)
      send_data image, :type => 'image/gif', :disposition => 'inline'
    else
      render :text => 'No barcode ID for this person.', :status => :missing
    end
  end

  private
    def check_access
      unless @logged_in.admin?(:manage_checkin)
        render :text => 'This section is only available to authorized users.', :layout => true
        return false
      end
    end
end
