class AdminController < ApplicationController
  before_filter :only_admins
  
  RECORD_LIMIT = 50
  
  def log
    raise 'Unauthorized' unless @logged_in.admin?(:view_log)
    conditions = []
    session[:admin_log] ||= {}
    session[:admin_log][:date] = params[:date] if params[:date]
    if session[:admin_log][:date]
      if session[:admin_log][:date][:from] and date_from = format_date(session[:admin_log][:date][:from])
        conditions.add_condition ['created_at >= ?', date_from]
      else
        session[:admin_log][:date][:from] = ''
      end
      if session[:admin_log][:date] and session[:admin_log][:date][:to] and date_to = format_date(session[:admin_log][:date][:to], '11:59 pm')
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
    @pages = Paginator.new self, LogItem.count('*', :conditions => conditions), 100, params[:page]
    @items = LogItem.find :all, :order => 'created_at desc', :limit => @pages.items_per_page, :offset => @pages.current.offset, :conditions => conditions
    #@items.delete_if { |i| i.object.nil? }
  end
  
  def mark_reviewed
    raise 'Unauthorized' unless @logged_in.admin?(:view_log)
    now = Time.now
    params[:log_items].each do |id|
      log_item = LogItem.find(id)
      log_item.reviewed_on = now
      log_item.reviewed_by = @logged_in
      log_item.save
    end
    redirect_to :action => 'log'
  end
  
  def photos
    raise 'Unauthorized' unless @logged_in.admin?(:view_log)
    @items = []
    filenames = Dir[File.join(RAILS_ROOT, 'db/photos/**/*.jpg')].select { |p| p =~ /\d+\.jpg/ }.sort{ |a, b| File.mtime(b) <=> File.mtime(a)}
    filenames[0...RECORD_LIMIT].each do |path|
      model_name = path.split('/')[-2].classify
      if ['Picture', 'Family', 'Group', 'Person', 'Recipe'].include? model_name
        model = eval(model_name)
        id = path.split('/').last.gsub(/\.jpg$/i, '').to_i
        if record = model.find(id) rescue nil
          @items << PhotoFile.new(path, record, File::Stat.new(path).mtime)
        end
      end
    end
  end
  
  def old_log
    raise 'Unauthorized' unless @logged_in.admin?(:view_log)
    @items = []
    filenames = Dir[File.join(RAILS_ROOT, 'db/photos/**/*.jpg')].select { |p| p =~ /\d+\.jpg/ }.sort{ |a, b| File.mtime(b) <=> File.mtime(a)}
    filenames[0...RECORD_LIMIT].each do |path|
      model_name = path.split('/')[-2].classify
      if ['Picture', 'Family', 'Group', 'Person', 'Recipe'].include? model_name
        model = eval(model_name)
        id = path.split('/').last.gsub(/\.jpg$/i, '').to_i
        if record = model.find(id) rescue nil
          @items << PhotoFile.new(path, record, File::Stat.new(path).mtime)
        end
      end
    end
    @items << Person.find(:all, :limit => RECORD_LIMIT, :order => 'updated_at desc')
    #@items << Family.find(:all, :limit => RECORD_LIMIT, :order => 'updated_at desc')
    @items << Group.find(:all, :limit => RECORD_LIMIT, :order => 'updated_at desc')
    @items << Verse.find(:all, :limit => RECORD_LIMIT, :order => 'updated_at desc')
    @items << Comment.find(:all, :limit => RECORD_LIMIT, :order => 'updated_at desc')
    @items << Message.find(:all, :limit => RECORD_LIMIT, :order => 'updated_at desc')
    #@items << Picture.find(:all, :limit => RECORD_LIMIT, :order => 'updated_at desc')
    @items << Recipe.find(:all, :limit => RECORD_LIMIT, :order => 'updated_at desc')
    @items << Tag.find(:all, :limit => RECORD_LIMIT, :order => 'updated_at desc')
    @items.flatten!
    @items = @items.select { |i| i.updated_at }
    @items.sort! { |a, b| b.updated_at.strftime('%Y%m%d%H%M%S') <=> a.updated_at.strftime('%Y%m%d%H%M%S') }
    @items = @items[0..100]
  end

  def updates
    raise 'Unauthorized' unless @logged_in.admin?(:manage_updates)
    @updates = Update.find_all_by_complete(params[:complete] == 'true')
    @unapproved_groups = Group.find_all_by_approved(false)
  end
  
  def toggle_complete
    raise 'Unauthorized' unless @logged_in.admin?(:manage_updates)
    @update = Update.find params[:id]
    @update.toggle! :complete
    if @update.complete and Setting.get(:features, :standalone_use)
      unless @update.do!
        flash[:warning] = 'There was an error saving this update.'
      end
      if params[:review]
        redirect_to edit_profile_path(:id => @update.person, :anchor => 'basics')
        return false
      end
    end
    redirect_to :action => 'updates'
  end

  def delete_update
    raise 'Unauthorized' unless @logged_in.admin?(:manage_updates)
    @update = Update.find params[:id]
    @update.destroy
    redirect_to :action => 'updates'
  end

  def index
    Admin.destroy_all '(select count(*) from people where people.admin_id = admins.id) = 0'
    @admins = Admin.find(:all, :order => 'people.last_name, people.first_name', :include => :person)
    @flag_count = LogItem.count '*', :conditions => 'reviewed_on is null and flagged_on is not null'
    @update_count = Update.count '*', :conditions => ['complete = ?', false]
    @group_count = Group.count '*', :conditions => ['approved = ?', false]
    @membership_request_count = MembershipRequest.count
    if @logged_in.super_admin?
      @privileges = nil
    else
      @privileges = Admin.privilege_columns.select { |c| @logged_in.admin.send(c.name+'?') }.map { |c| c.name.gsub('_', ' ') }
    end
  end
  
  def membership_requests
    raise 'Unauthorized' unless @logged_in.admin?(:manage_groups)
    @reqs_by_group = MembershipRequest.find(:all).select { |r| r.group }.group_by &:group
  end
  
  def edit_attribute
    render :update do |page|
      if @logged_in.admin?(:manage_access)
        Admin.find(params[:id]).update_attribute params[:name], params[:value]
        status_id = "#{params[:name]}_#{params[:id]}_status"
        page.show status_id
        page.replace_html status_id, '<img src="/images/checkmark.png" class="icon"/>'
        page.visual_effect :fade, status_id
      else
        page.alert('You are not authorized to make changes on this page.')
      end
    end
  end
  
  def add_admin
    if @logged_in.admin?(:manage_access)
      params[:people].to_a.each do |id|
        person = Person.find(id)
        if person.super_admin?
          flash[:notice] = "#{person.name} is a Super Administrator."
        else
          person.admin = Admin.create!
          unless person.save
            flash[:warning] = person.errors.full_messages.join('; ')
          end
        end
      end
    else
      flash[:warning] = 'You are not authorized to do that.'
    end
    redirect_to :action => 'index'
  end
  
  def remove_admin
    if @logged_in.admin?(:manage_access)
      Admin.find(params[:id]).destroy
    end
    redirect_to :action => 'index'
  end
  
  private
  
    def format_date(date, default_time=nil)
      if default_time and date !~ /:/
        date += " #{default_time}"
      end
      DateTime.parse(date) rescue nil
    end
end

PhotoFile = Struct.new('PhotoFile', :path, :record, :updated_at)
