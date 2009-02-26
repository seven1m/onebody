begin
  if recipient = Setting.get(:contact, :bug_notification_email)
    ExceptionNotifier.exception_recipients = [recipient]
  end
rescue
  puts 'Error reading settings for bug notification (OK if running setup).'
end
