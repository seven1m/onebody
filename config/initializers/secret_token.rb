# TODO remove this with Rails 4.1
token = Rails.application.secrets.secret_token
if token == 'SOMETHING_RANDOM_HERE'
  raise StandardError.new('You forgot to set the secret token in config/secrets.yml')
else
  OneBody::Application.config.secret_key_base = token
end
