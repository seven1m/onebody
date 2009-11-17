class Administration::DashboardsController < ApplicationController
  before_filter :only_admins
  
  def show
    Admin.destroy_all '(select count(*) from people where people.admin_id = admins.id) = 0'
    @admin_count = Person.count('*', :conditions => ['admin_id is not null'])
    @update_count = Update.count '*', :conditions => {:complete => false}
    @email_changed_count = Person.count '*', :conditions => {:email_changed => true, :deleted => false}
    @group_count = Group.count '*', :conditions => {:approved => false}
    @membership_request_count = MembershipRequest.count
    @last_sync = Sync.last(:order => 'created_at')
    if @logged_in.super_admin?
      @privileges = nil
    else
      @privileges = Admin.privileges.select { |p| @logged_in.admin.flags[p] }.map { |p| p.humanize }
    end
  end

end
