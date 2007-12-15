ExceptionNotifier.exception_recipients = [SETTINGS['contact']['bug_notification_email']] if SETTINGS['contact']['bug_notification_email']
ExceptionNotifier.sender_address = "\"One Body Error\" <app-error@#{SETTINGS['email']['domain']}>"
