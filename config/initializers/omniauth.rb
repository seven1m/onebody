Rails.application.config.middleware.use OmniAuth::Builder do
  provider :facebook, setup: true
end
