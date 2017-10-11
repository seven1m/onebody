class ReportsController < ApplicationController
  REPORTS = {
    'attendance_totals'     => AttendanceTotalsReport,
    'group_contact_details' => GroupContactDetailsReport,
    'weekly_attendance'     => WeeklyAttendanceReport
  }.freeze

  def show
    report_class = REPORTS[params[:id]]
    raise ActiveRecord::RecordNotFound unless report_class
    @report = report_class.new(params.to_unsafe_h[:options] || {})
    respond_to do |format|
      format.html do
        render file: Rails.root.join('app/views/reports', params[:id] + '.html.haml')
      end
      format.csv do
        send_data @report.to_csv, filename: params[:id] + '.csv', type: 'text/csv'
      end
    end
  end
end
