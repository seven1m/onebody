module CheckinPlugin
  class Routes
    def draw(map)
    
      map.with_options :controller => 'checkin' do |m|
        m.checkin 'checkin', :action => 'index'
        m.checkin_date_and_time 'checkin/date_and_time', :action => 'date_and_time'
        m.report_date_and_time 'checkin/report_date_and_time', :action => 'report_date_and_time'
        m.checkin_section 'checkin/:section', :action => 'section'
        m.check 'checkin/:section/check', :action => 'check'
        m.checkin_attendance 'checkin/:section/attendance', :action => 'attendance'
        m.void_attendance_record 'checkin/:section/void', :action => 'void'
      end
      
      map.with_options :controller => 'checkin/admin' do |m|
        # FIXME: cannot get next route to work minus "index" on the end - clashes with checkin_section route
        m.checkin_admin 'checkin/admin/index', :action => 'index'
        m.checkin_report 'checkin/admin/report', :action => 'report'
      end
      
    end
  end
end
