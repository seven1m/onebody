Rails.application.config.middleware.use OmniAuth::Builder do
  facebook_auth = Rails.application.secrets['facebook_auth']
  provider :facebook, facebook_auth['app_id'], facebook_auth['app_secret'], :scope => 'email,read_stream' if facebook_auth
end
