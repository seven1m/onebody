# Mix this module into the main application module to provide
# information about the current email configuration
#
# In config/application.rb:
#
#     module OneBody
#       extend EmailConfigInfo
#     end
#
module EmailConfigInfo
  def email_configured?
    config = smtp_config
    config['address'].present? && config['user_name'] != 'SMTP_LOGIN_GOES_HERE'
  end

  def smtp_config
    return {} unless File.exist?(email_config_path)
    YAML.load_file(email_config_path).fetch(Rails.env.to_s, {}).fetch('smtp', {})
  end

  def email_config_path
    Rails.root.join('config/email.yml')
  end

  def load_email_config
    config = smtp_config
    return unless config.any?
    config.symbolize_keys!
    config[:authentication] = config[:authentication].to_sym if config[:authentication]
    ActionMailer::Base.smtp_settings = config
  end
end
