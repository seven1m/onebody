class Administration::DashboardsController < ApplicationController
  before_filter :only_admins

  def show
    Admin.destroy_all '(select count(*) from people where people.admin_id = admins.id) = 0'
    @admin_count = Person.count(conditions: ['admin_id is not null'])
    @update_count = Update.count(conditions: {complete: false})
    @email_changed_count = Person.count(conditions: {email_changed: true, deleted: false})
    @groups_pending_approval_count = Group.count(conditions: {approved: false})
    @membership_request_count = MembershipRequest.count
    if @attendance_last_date = AttendanceRecord.maximum(:attended_at)
      @attendance_records_count = AttendanceRecord.count(conditions: ["date(attended_at) = date(?)", @attendance_last_date])
    end
    @last_sync = Sync.last(order: 'created_at')
    @sync_counts = @last_sync.count_items if @last_sync
    @daily_update_counts = Update.daily_counts(15, 0, '%b %d', ['%a', 'Sun'])
    @daily_message_counts = Message.daily_counts(15, 0, '%b %d', ['%a', 'Sun'])
    @group_type_counts = Group.count_by_type
    @linked_group_counts = Group.count_by_linked
    @daily_attendance_counts = AttendanceRecord.daily_counts(15, 0, '%b %d', ['%a', 'Sun'])
    @person_count = Person.count('id', conditions: {deleted: false})
    @family_count = Family.count('id', conditions: {deleted: false})
    @group_count  = Group.count('id')
    @unsynced_to_donortools = Person.unsynced_to_donortools.count
    @deleted_people_count = Person.where(deleted: true).count
    @alerts = []
  end

end
