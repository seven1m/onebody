class PrayerSignupsController < ApplicationController
  def index
    if Setting.get(:features, :prayer_event)
      get_first_and_last
      if @first and @last
        get_signups
        set_now
        respond_to do |format|
          format.html
          format.js do
            get_first_and_last
            get_signups
            set_now
          end
        end
      else
        render text: t('prayer_signups.misconfigured'), layout: true
      end
    else
      render text: t('feature_unavailable'), layout: true
    end
  end

  def create
    @start = DateTime.parse(params[:start]) rescue nil
    if id = params[:person_id] || params[:ids].to_a.first and id.to_i > 0 and @start
      create_by_id(id)
    elsif params[:other_name].to_s.any? and @start
      create_by_name(params[:other_name])
    else
      render nothing: true
    end
  end

  def create_by_id(id)
    person = Person.find(id)
    if person == @logged_in or @logged_in.admin?(:manage_prayer_signups)
      signup = person.prayer_signups.create(start: @start.to_time)
      respond_to_signup(signup)
    else
      respond_to_unauthorized
    end
  end

  def create_by_name(name)
    if @logged_in.admin?(:manage_prayer_signups)
      signup = PrayerSignup.create(start: @start.to_time, other_name: name)
      respond_to_signup(signup)
    else
      respond_to_unauthorized
    end
  end

  def respond_to_signup(signup)
    respond_to do |format|
      format.html do
        if signup.errors.any?
          flash[:warning] = signup.errors.full_messages.join('; ')
        else
          flash[:notice] = t('prayer_signups.signup_saved')
        end
        redirect_to prayer_signups_path
      end
      format.js do
        get_first_and_last
        get_signups
        set_now
      end
    end
  end

  def respond_to_unauthorized
    respond_to do |format|
      format.html do
        render text: t('not_authorized'), layout: true, status: 401
      end
      format.js do
        render(:update) do |page|
          page.alert(t('not_authorized'))
        end
      end
    end
  end

  def destroy
    signup = PrayerSignup.find(params[:id])
    if (signup.person == @logged_in or @logged_in.admin?(:manage_prayer_signups))
      @start = signup.start
      signup.destroy
      flash[:notice] = t('prayer_signups.signup_removed')
    end
    respond_to do |format|
      format.html { redirect_to prayer_signups_path }
      format.js { get_first_and_last; get_signups; set_now }
    end
  end

  private

    def get_first_and_last
      @first = DateTime.parse(Setting.get(:features, :prayer_event_first_date_and_time)) rescue nil
      @last = DateTime.parse(Setting.get(:features, :prayer_event_last_date_and_time)) rescue nil
    end

    def get_signups
      signups = PrayerSignup.all(conditions: ['start >= ? and start <= ?', @first, @last], order: 'start')
      @signups = signups.group_by { |r| r.start.strftime('%Y/%m/%d %H:%M') }
      @count_per_day = {}
      signups.each do |s|
        d = s.start.strftime('%Y/%m/%d')
        h = s.start.strftime('%H:%M')
        @count_per_day[d] ||= []
        unless @count_per_day[d].include? h
          @count_per_day[d] << h
        end
      end
    end

    def set_now
      now = DateTime.now
      @now = DateTime.new(now.year, now.month, now.day, now.hour, now.min)
    end
end
