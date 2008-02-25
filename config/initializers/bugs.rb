begin
  ExceptionNotifier.exception_recipients = [Setting.get(:contact, :bug_notification_email)] if Setting.get(:contact, :bug_notification_email)
  ExceptionNotifier.sender_address = "\"One Body Error\" <app-error@#{Setting.get(:email, :domain)}>"
rescue
  puts 'Error reading settings for bug notification (OK if running migrations).'
end
