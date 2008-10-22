unless Rails.env == 'test'
  begin
    settings = {
      :address        => Setting.get(:email, :host),
      :port           => 25,
      :domain         => Setting.get(:email, :domain)
    }
    if Setting.get(:email, :authentication_required)
      settings.merge!({
        :authentication => :login,
        :user_name      => Setting.get(:email, :smtp_username),
        :password       => Setting.get(:email, :smtp_password)
      })
    end
    ActionMailer::Base.smtp_settings = settings
  rescue
    puts 'Error reading settings for smtp connection setup (OK if running setup).'
  end
end

unless defined? VALID_EMAIL_ADDRESS
  VALID_EMAIL_ADDRESS = /^[a-z\-_0-9\.%]+\@[a-z\-0-9\.]+\.[a-z\-]{2,4}$/i

  MAX_DAYS_FOR_REPLIES = 100
  MAX_DAILY_VERIFICATION_ATTEMPTS = 3

  ATTACHMENTS_TO_IGNORE = ['winmail.dat']
end
