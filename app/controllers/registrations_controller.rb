class RegistrationsController < ApplicationController
  before_action :load_event, only: %w(index new create)
  skip_before_action :authenticate_user

  layout 'event_registrations'

  def index
    redirect_to action: :new
  end

  def new
    @registration = @event.registrations.new
  end

  def create
    if current_user
      @registration = @event.registrations.create!(person: current_user)
      redirect_to edit_registration_path(@registration)
    else
      redirect_to(action: :new) && return unless params[:email].present? && params[:name].present?
      Verification.create!(email: params[:email], name: params[:name], event: @event)
    end
  end

  def edit
    @registration = current_user.registrations.find(params[:id])
    @event = @registration.event
    @registrant = params[:registrant_id] ?
                  @registration.registrants.find(params[:registrant_id]) :
                  @registration.registrants.first
  end

  private

  def load_event
    @event = Event.find(params[:event_id])
  end

  def current_user
    return unless session[:registration_logged_in_id]
    @current_user ||= Person.find(session[:registration_logged_in_id])
  end

  helper_method :current_user
end
