class EventsController < ApplicationController

  def index
    today = Date.today
    @year = (params[:year] || today.year).to_i
    @month = (params[:month] || today.month).to_i
    @events = Event.find(
      :all,
      :conditions => ['year(`when`) = ? and month(`when`) = ?', @year, @month],
      :order => '"when"'
    ).group_by { |e| e.when && e.when.strftime('%Y-%m-%d') }
    @years_to_show = Event.minimum("year(`when`)")..Event.maximum("year(`when`)")
  end
  
  def calendar
    index
    render :partial => 'calendar'
  end
  
  def list
    @pages = Paginator.new self, Event.count, 25, params[:page]
    @events = Event.find :all,
      :order => '"when" desc',
      :limit => @pages.items_per_page,
      :offset => @pages.current.offset
  end

  def view
    @event = Event.find params[:id]
  end
  
  def edit
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
        redirect_to :action => 'view', :id => @event
      else
        flash[:notice] = @event.errors.full_messages.join('; ')
      end
    end
  end
  
  def delete
    @event = Event.find params[:id]
    @event.destroy if @event.admin? @logged_in
    redirect_to :action => 'index'
  end

end
