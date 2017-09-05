class Checkin::CheckinsController < ApplicationController
  before_action :ensure_campus_selection

  layout 'checkin'

  # show UI
  def show
    session[:checkin_printer_id] = params[:printer].presence if params[:printer]
    @checkin = CheckinPresenter.new(session[:checkin_campus])
  end

  # scan barcode
  def create
    if @family = Family.undeleted.by_barcode(params[:barcode]).first
      session[:barcode] = params[:barcode]
      @checkin = CheckinPresenter.new(session[:checkin_campus], @family)
      render json: @checkin
    else
      render json: { error: t('checkin.scan.unknown_card') }
    end
  end

  # complete check-in
  def update
    labels = {}
    people = params[:people].to_unsafe_h # simple ids, not passed as attributes to a model
    people.each do |person_id, times|
      records = AttendanceRecord.check_in(person_id, times, session[:barcode])
      labels[person_id] = AttendanceRecord.labels_for(records)
    end
    render json: {
      labels: labels,
      today: Date.current.to_s(:date),
      community_name: Setting.get(:name, :community)
    }
  end

  private

  def authenticate_user
    authenticate_user_for_checkin
  end

  def ensure_campus_selection
    if params[:campus]
      session[:checkin_campus] = params[:campus]
    elsif !session[:checkin_campus]
      @campuses = CheckinTime.campuses
      if @campuses.none?
        render action: 'run_setup'
      elsif @campuses.length == 1
        session[:checkin_campus] = @campuses.first
      else
        render action: 'campus_select'
        return false
      end
    end
  end

  def feature_enabled?
    unless Setting.get(:features, :checkin)
      render plain: 'This feature is unavailable.', layout: true
      false
    end
  end
end
