begin
  if (recipient = Setting.get(:contact, :bug_notification_email)).to_s.any?
    OneBody::Application.config.middleware.use ExceptionNotifier,
      :email_prefix         => "[OneBody] ",
      :sender_address       => recipient,
      :exception_recipients => [recipient]
  end
rescue
  # no biggie
end
