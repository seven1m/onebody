Rails.application.config.middleware.use OmniAuth::Builder do
  if Site.current
    facebook_app_id = Setting.get(:facebook, :app_id)
    facebook_app_secret = Setting.get(:facebook, :app_secret)
    provider :facebook, facebook_app_id, facebook_app_secret, :scope => 'email,read_stream' if facebook_app_id and facebook_app_secret
  end
end
