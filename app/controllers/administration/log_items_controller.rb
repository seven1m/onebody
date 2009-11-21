class Administration::LogItemsController < ApplicationController
  before_filter :only_admins
  
  def index
    conditions = []
    session[:admin_log] ||= {}
    session[:admin_log][:date] = params[:date] || {}
    session[:admin_log][:date][:from] = (Date.today - 7).to_s unless session[:admin_log][:date][:from].to_s.any?
    if session[:admin_log][:date]
      if session[:admin_log][:date][:from].to_s.any? and date_from = format_date(session[:admin_log][:date][:from])
        conditions.add_condition ['created_at >= ?', date_from]
      else
        session[:admin_log][:date][:from] = ''
      end
      if session[:admin_log][:date] and session[:admin_log][:date][:to].to_s.any? and date_to = format_date(session[:admin_log][:date][:to], '11:59 pm')
        conditions.add_condition ['created_at <= ?', date_to]
      else
        session[:admin_log][:date][:to] = ''
      end
    end
    session[:admin_log][:reviewed] = params[:reviewed] if params[:reviewed]
    session[:admin_log][:nonflagged] = params[:nonflagged] if params[:nonflagged]
    conditions.add_condition ['reviewed_on is null'] unless session[:admin_log][:reviewed] == 'visible'
    conditions.add_condition ['flagged_on is not null'] unless session[:admin_log][:nonflagged] == 'visible'
    conditions = nil if conditions.empty?
    @items = LogItem.paginate(:order => 'id desc', :conditions => conditions, :page => params[:page])
  end
  
  def show
    @item = LogItem.find(params[:id])
    respond_to do |format|
      format.js
    end
  end
  
  def batch
    now = Time.now
    params[:log_items].each do |id|
      log_item = LogItem.find(id)
      log_item.reviewed_on = now
      log_item.reviewed_by = @logged_in
      log_item.save
    end
    redirect_to administration_log_items_path
  end
  
  private
  
    def format_date(date, default_time=nil)
      if default_time and date !~ /:/
        date += " #{default_time}"
      end
      DateTime.parse(date) rescue nil
    end
  
    def only_admins
      unless @logged_in.admin?(:view_log)
        render :text => 'You must be an administrator to use this section.', :layout => true, :status => 401
        return false
      end
    end

end
