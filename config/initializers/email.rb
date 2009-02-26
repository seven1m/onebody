ActionMailer::Base.smtp_settings = YAML::load_file(File.dirname(__FILE__) + '/../email.yml')[Rails.env]['smtp'] rescue nil

unless defined? VALID_EMAIL_ADDRESS
  VALID_EMAIL_ADDRESS = /^[a-z\-_0-9\.%]+\@[a-z\-0-9\.]+\.[a-z\-]{2,4}$/i

  MAX_DAYS_FOR_REPLIES = 100
  MAX_DAILY_VERIFICATION_ATTEMPTS = 3

  ATTACHMENTS_TO_IGNORE = ['winmail.dat']
end
