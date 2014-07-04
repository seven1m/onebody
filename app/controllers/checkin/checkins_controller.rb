class Checkin::CheckinsController < ApplicationController

  skip_before_filter :authenticate_user
  before_filter :ensure_campus_selection
  before_filter :reset_family, except: :edit
  before_filter -> {
    Timecop.freeze(Time.local(2014, 6, 29, 9, 00)) # TEMP for testing the UI
  }

  layout 'checkin'

  def show
    render action: 'new'
  end

  def new
  end

  def create
    if @family = Family.undeleted.by_barcode(params[:barcode]).first
      session[:checkin_family_id] = @family.id
      redirect_to edit_checkin_path
    else
      flash[:error] = 'card unknown'
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
      records = AttendanceRecord.check_in(person, times)
      records.compact.each do |record|
        labels[person.id] ||= []
        labels[person.id] << record.as_json if record.print_nametag? and labels[person.id].empty?
        labels[person.id] << record.as_json if record.print_extra_nametag? and labels[person.id].length < 2
      end
    end
    #session.delete(:checkin_family_id)
    render json: { labels: labels }
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
