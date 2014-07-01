class Administration::DashboardsController < ApplicationController
  before_filter :only_admins

  # TODO refactor into presenter
  def show
    @admin_count = Person.administrators.count
    @update_count = Update.pending.count
    @email_changed_count = Person.email_changed.count
    @groups_pending_approval_count = Group.unapproved.count
    @membership_request_count = MembershipRequest.count
    if @attendance_last_date = AttendanceRecord.maximum(:attended_at)
      @attendance_records_count = AttendanceRecord.on_date(@attendance_last_date).count
    end
    @last_sync = Sync.last(order: 'created_at')
    @sync_counts = @last_sync.count_items if @last_sync
    @group_type_counts = Group.count_by_type
    @linked_group_counts = Group.count_by_linked
    @person_count = Person.undeleted.count
    @family_count = Family.undeleted.count
    @group_count  = Group.count
    @deleted_people_count = Person.deleted.count
    @alerts = []
  end

end
