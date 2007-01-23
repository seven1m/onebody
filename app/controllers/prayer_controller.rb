class PrayerController < ApplicationController
  def event
    @first = DateTime.new(2007, 1, 21, 12)
    @last = DateTime.new(2007, 1, 30, 17)
    signups = PrayerSignup.find :all, :conditions => ['start >= ? and start <= ?', @first, @last], :order => 'start'
    @signups = signups.group_by { |r| r.start.strftime '%Y/%m/%d %H:%M' }
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
  
  def event_signup
    person = Person.find params[:id]
    if (person == @logged_in or @logged_in.admin?) and params[:start]
      if s = person.prayer_signups.find_by_start(params[:start])
        s.destroy
        flash[:notice] = 'Removed from time slot'
      else
        signup = person.prayer_signups.create :start => params[:start]
        if signup.errors.any?
          flash[:notice] = signup.errors.full_messages.join('; ')
        else
          flash[:notice] = 'Signup successful!'
        end
      end
    else
      raise 'You are not authorized to do that'
    end
    redirect_to :action => 'event'
  end
end
