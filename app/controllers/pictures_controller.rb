class PicturesController < ApplicationController
  
  def index
    @pages = Paginator.new self, Picture.count, 25, params[:page]
    @pictures = Picture.find :all,
      :order => 'created_at desc',
      :limit => @pages.items_per_page,
      :offset => @pages.current.offset
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
    success = fail = 0
    (1..10).each do |index|
      if ((pic = params["picture#{index}"]).read rescue '').length > 0
        pic.seek(0)
        picture = @event.pictures.create :person => (params[:remove_owner] ? nil : @logged_in)
        picture.photo = pic
        if picture.has_photo?
          success += 1
        else
          fail += 1
          picture.log_item.destroy rescue nil
          picture.destroy rescue nil
        end
      end
    end
    flash[:notice] = "#{success} picture(s) saved"
    flash[:notice] += " (#{fail} not saved due to errors)" if fail > 0
    redirect_to :controller => 'events', :action => 'view', :id => @event
  end
  
  def delete
    @picture = Picture.find params[:id]
    if @picture.event.admin? @logged_in
      @picture.destroy
      flash[:notice] = 'Picture deleted.'
    end
    redirect_to :controller => 'events', :action => 'view', :id => @picture.event
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
