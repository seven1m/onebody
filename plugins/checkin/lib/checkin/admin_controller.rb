class Checkin::AdminController < ApplicationController
  ORDERS = {'Time In' => "`in`", 'Time Out' => "`out`", 'Age' => 'age', 'Name' => "first_name last_name"}
  before_filter :only_admins
  
  def index
    @sections = Setting.get(:features, :checkin_sections, %w(Preschool Elementary))
    @last_sunday_or_wednesday = Date.today
    while not [0, 3].include? @last_sunday_or_wednesday.wday
      @last_sunday_or_wednesday -= 1
    end
    @orders = ORDERS
  end
  
  def report
    @date = Date.parse(params[:date])
    @section = params[:section]
    conditions = ["`in` >= ? and `in` < ? and section = ?", @date, @date+1, @section]
    if params[:time].to_s.any?
      @time = DateTime.parse(@date.strftime('%m/%d/%Y ') + params[:time])
      conditions.add_condition ["`in` #{params[:time_relevance] == 'before' ? '<' : '>='} ?", @time]
    end
    @order = params[:order]
    unless ORDERS.values.include? @order
      @order = "`in`"
    end
    @records = CheckinAttendanceRecord.find(
      :all,
      :conditions => conditions,
      :order => @order
    )
  end
  
  private
  
    def only_admins
       unless @logged_in.admin?(:manage_checkin)
         render :text => 'This section is only available to authorized users.', :layout => true
         return false
       end
    end
end
