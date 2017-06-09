class Administration::DashboardsController < ApplicationController
  before_filter :only_admins

  # TODO: refactor into presenter
  def show
    @admin_count = Person.administrators.count
    @update_count = Update.pending.count
    @email_changed_count = Person.email_changed.count
    @last_import = Import.last
    @import_errors_count = @last_import ? @last_import.rows.errored.count : 0
    @groups_pending_approval_count = Group.unapproved.count
    @membership_request_count = MembershipRequest.count
    if @attendance_last_date = AttendanceRecord.maximum(:attended_at)
      @attendance_records_count = AttendanceRecord.on_date(@attendance_last_date).count
    end
    @person_count = Person.undeleted.count
    @family_count = Family.undeleted.count
    @group_count  = Group.count
    @deleted_people_count = Person.deleted.count
    @alerts = []
  end
end
