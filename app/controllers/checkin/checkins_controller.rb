class Checkin::CheckinsController < ApplicationController

  skip_before_filter :authenticate_user
  before_filter :ensure_campus_selection
  before_filter -> {
    Timecop.freeze(Time.local(2014, 6, 29, 9, 00)) # TEMP for testing the UI
  }
  after_filter -> {
    Timecop.return
  }

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
    @checkins = @family.people.undeleted.map do |person|
      CheckinPresenter.new(session[:checkin_campus], person)
    end
  end

  def update
    labels = {}
    params[:people].each do |person_id, times|
      person = Person.find(person_id)
      records = AttendanceRecord.check_in(person, times, session[:barcode])
      labels[person.id] = AttendanceRecord.labels_for(records)
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
      if (@campuses = CheckinTime.campuses).length == 1
        session[:checkin_campus] = @campuses.first
      else
        render action: 'campus_select'
        return false
      end
    end
  end

  def reset_family
    #session.delete(:checkin_family_id) # TODO
  end

end
