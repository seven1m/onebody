class Administration::EventsController < ApplicationController
  before_filter :only_admins

  def index
    @events = Event.order(:name)
  end

  def show
    @event = Event.find(params[:id])
  end

  def new
    @event = Event.new
  end

  def create
    @event = Event.new(event_params)
    if @event.save
      redirect_to administration_event_path(@event)
    else
      render action: :new
    end
  end

  def edit
    @event = Event.find(params[:id])
  end

  def update
    @event = Event.find(params[:id])
    @event.attributes = event_params
    if @event.save
      redirect_to administration_event_path(@event)
    else
      render action: :edit
    end
  end

  def destroy
    @event = Event.find(params[:id])
    @event.destroy
    redirect_to administration_events_path
  end

  private

  def event_params
    params.require(:event).permit(:name, :description, :visibility, :registration_starts_at, :registration_ends_at)
  end

  def only_admins
    return if @logged_in.admin?(:manage_event_registration)
    render text: t('only_admins'), layout: true, status: 401
    return false
  end
end
