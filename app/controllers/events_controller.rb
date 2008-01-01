class EventsController < ApplicationController

  def index
    today = Date.today
    @year = (params[:year] || today.year).to_i
    @month = (params[:month] || today.month).to_i
    @events = Event.find(
      :all,
      :conditions => ["#{sql_year('`when`')} = ? and #{sql_month('`when`')} = ?", @year, @month],
      :order => '"when"'
    ).group_by { |e| e.when && e.when.strftime('%m/%d/%Y') }
    first = [Event.minimum(sql_year('`when`')).to_i, today.year].max - 1
    last = [Event.maximum(sql_year('`when`')).to_i, today.year].max + 1
    @years_to_show = first..last
  end
  
  def calendar
    index
    render :partial => 'calendar'
  end
  
  def list
    conditions = []
    conditions.add_condition ["#{sql_year('`when`')} = ?", params[:year]] if params[:year]
    conditions.add_condition ["#{sql_month('`when`')} = ?", params[:month]] if params[:month]
    conditions = nil if conditions.empty?
    @pages = Paginator.new self, Event.count('*', :conditions => conditions), 25, params[:page]
    @events = Event.find :all,
      :conditions => conditions,
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
      @event = Event.new :person => @logged_in, :when => params[:when]
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
  
  def add_verse
    verse = Verse.find_or_create_by_reference(Verse.normalize_reference(params[:reference]))
    if verse.errors.any?
      flash[:notice] = 'There was an error adding the verse. Make sure you entered the right reference.'
      redirect_to :action => 'view', :id => params[:id]
    else
      event = Event.find(params[:id])
      verse.events << event unless event.verses.include? verse
      flash[:notice] = 'Verse saved.'
      redirect_to :controller => 'events', :action => 'view', :id => params[:id], :anchor => 'verses'
    end
  end
  
  def remove_verse
    verse = Verse.find params[:verse_id]
    verse.events.delete Event.find(params[:id])
    flash[:notice] = 'Verse removed.'
    redirect_to :action => 'view', :id => params[:id], :anchor => 'verses'
  end

end
