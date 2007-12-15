ActionMailer::Base.smtp_settings = {
  :address => SETTINGS['email']['host'],
  :port => 25,
  :domain => SETTINGS['email']['domain']
}

VALID_EMAIL_ADDRESS = /^[a-z\-_0-9\.]+\@[a-z\-0-9\.]+\.[a-z]{2,4}$/i
VALID_EMAIL_RE = /^[A-Z0-9\._%\-]+@[A-Z0-9\.\-]+\.[A-Z]{2,4}$/i

MAX_DAYS_FOR_REPLIES = 100
MAX_DAILY_VERIFICATION_ATTEMPTS = 3

ATTACHMENTS_TO_IGNORE = ['winmail.dat']
