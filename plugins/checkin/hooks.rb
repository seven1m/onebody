PLUGIN_HOOKS[:more_page] << [
  'checkin/more_page_link',
  Proc.new { |c| l = c.instance_eval('@logged_in') and (l.checkin_access? or l.admin?(:manage_checkin)) }
]
