class CheckinController < ApplicationController
  before_filter :check_access
  before_filter :get_sections, :only => %w(index section check attendance void)
  
  def index
  end
  
  def section
    attendance(true)
  end
  
  def check
    if @person = Person.find_by_barcode_id(params[:id]) \
      and rec = CheckinAttendanceRecord.check(@person, @section) \
      and rec.errors.empty?
      @highlight = rec
    else
      flash[:warning] = "There was an error scanning this ID: #{params[:id]}"
      flash[:warning] += "<br/>No one was found with that ID number." unless rec
      flash[:warning] += "<br/>#{rec.errors.full_messages.join('; ')}" if rec and rec.errors.any?
      @error = true
    end
    attendance(true)
    respond_to do |format|
      format.js
      format.html { redirect_to checkin_section_url(:section => params[:section]) }
    end
  end
  
  def void
    @record = CheckinAttendanceRecord.find(params[:id])
    @record.update_attribute :void, true
    attendance
  end
  
  def attendance(dont_render=false)
    @records = CheckinAttendanceRecord.find(
      :all,
      :conditions => ['section = ? and `in` >= ?', @section, Date.today],
      :order => '`in` desc'
    )
    render :partial => 'attendance' unless dont_render
  end
  
  def date_and_time
    respond_to do |format|
      format.js
    end
  end
  
  def report_date_and_time
    Notifier.deliver_date_and_time_report unless session[:delivered_date_and_time_report]
    session[:delivered_date_and_time_report] = true
    respond_to do |format|
      format.js
    end
  end
  
  def report
    unless @logged_in.admin?(:manage_checkin)
      render :text => 'This section is only available to authorized users.', :layout => true
      return false
    end
  end
  
  private
    def get_sections
      @sections = {}
      Setting.get(:features, :checkin_sections, %w(Elementary Preschool)).each do |section|
        @sections[section.gsub(/\s/, '_').downcase] = section
      end
      @section = @sections[params[:section]] if params[:section]
    end
    
    def check_access
      unless @logged_in.admin?(:manage_checkin) or @logged_in.checkin_access?
        render :text => 'This section is only available to authorized users.', :layout => true
        return false
      end
    end
end
