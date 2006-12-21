class PicturesController < ApplicationController
  def index
    @events = Event.find :all, :order => '"when"'
  end
  
  def view_event
    @event = Event.find params[:id]
  end
  
  def edit_event
    if params[:id]
      @event = Event.find params[:id]
    else
      @event = Event.new :person => @logged_in
    end
    unless @event.admin?(@logged_in)
      raise 'You are not authorized to edit this event.'
    end
    if request.post?
      params[:event].cleanse 'when'
      if @event.update_attributes params[:event]
        redirect_to :action => 'view_event', :id => @event
      else
        flash[:notice] = @event.errors.full_messages.join('; ')
      end
    end
  end
  
  def delete_event
    @event = Event.find params[:id]
    @event.destroy if @event.admin? @logged_in
    redirect_to :action => 'index'
  end
  
  def view
    @picture = Picture.find params[:id]
  end

  def next
    @event = Picture.find(params[:id]).event
    unless pic = @event.pictures.find(:first, :conditions => ['id > ?', params[:id]], :order => 'id')
      pic = @event.pictures.find :first
    end
    redirect_to :action => 'view', :id => pic
  end

  def prev
    @event = Picture.find(params[:id]).event
    unless pic = @event.pictures.find(:first, :conditions => ['id < ?', params[:id]], :order => 'id desc')
      pic = @event.pictures.find(:all).last
    end
    redirect_to :action => 'view', :id => pic
  end
  
  def add_picture
    @event = Event.find params[:id]
    if @event.admin? @logged_in
      success = fail = 0
      (1..10).each do |index|
        if (pic = params["picture#{index}"]).read.length > 0
          pic.seek(0)
          picture = @event.pictures.create :person => (params[:remove_owner] ? nil : @logged_in)
          picture.photo = pic
          if picture.has_photo?
            success += 1
          else
            fail += 1
            picture.destroy
          end
        end
      end
      flash[:notice] = "#{success} picture(s) saved"
      flash[:notice] += " (#{fail} not saved due to errors)" if fail > 0
    end
    redirect_to :action => 'view_event', :id => @event
  end
  
  def delete
    @picture = Picture.find params[:id]
    if @picture.event.admin? @logged_in
      @picture.destroy
      flash[:notice] = 'Picture deleted.'
    end
    redirect_to :action => 'view_event', :id => @picture.event
  end
  
  def rotate
    @picture = Picture.find params[:id]
    if @picture.event.admin? @logged_in
      @picture.rotate_photo params[:degrees].to_i
    end
    flash[:refresh] = true
    redirect_to :action => 'view', :id => @picture
  end
  
  def select_event_cover
    @picture = Picture.find params[:id]
    if @picture.event.admin? @logged_in
      @picture.event.pictures.update_all 'cover = 0'
      @picture.update_attribute :cover, true
      flash[:notice] = 'Cover picture updated.'
    end
    redirect_to :action => 'view', :id => @picture
  end
  
  def photo
    send_photo Picture.find(params[:id].to_i)
  end
end
