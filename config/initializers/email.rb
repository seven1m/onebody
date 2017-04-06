OneBody.load_email_config

unless defined? VALID_EMAIL_ADDRESS
  VALID_EMAIL_ADDRESS = /\A[a-z\-_0-9\.%]+(\+[a-z\-_0-9\.%]+)?\@[a-z\-0-9\.]+\.[a-z\-]{2,}\z/i

  MAX_DAILY_VERIFICATION_ATTEMPTS = 10

  ATTACHMENTS_TO_IGNORE = ['winmail.dat']
end
