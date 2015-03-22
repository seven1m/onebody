class Checkin::CheckinsController < ApplicationController

  skip_before_filter :authenticate_user
  before_filter :ensure_campus_selection

  layout 'checkin'

  def show
    render action: 'new'
  end

  def new
    session.delete(:checkin_family_id)
    session.delete(:barcode)
  end

  def create
    if @family = Family.undeleted.by_barcode(params[:barcode]).first
      session[:checkin_family_id] = @family.id
      session[:barcode] = params[:barcode]
      redirect_to edit_checkin_path
    else
      flash.now[:error] = t('checkin.scan.unknown_card')
      render action: 'new'
    end
  end

  def edit
    return redirect_to(action: 'show') unless session[:checkin_family_id]
    @family = Family.find(session[:checkin_family_id])
    @checkin = CheckinPresenter.new(session[:checkin_campus], @family)
  end

  def update
    labels = {}
    params[:people].each do |person_id, times|
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

  def ensure_campus_selection
    if params[:campus]
      session[:checkin_campus] = params[:campus]
    elsif not session[:checkin_campus]
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
      render text: 'This feature is unavailable.', layout: true
      false
    end
  end

end
