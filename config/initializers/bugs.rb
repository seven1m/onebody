begin
  if recipient = Setting.get(:contact, :bug_notification_email)
    ExceptionNotifier.exception_recipients = [recipient]
  end
rescue
  # no biggie
end
