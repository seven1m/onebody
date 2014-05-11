secrets = YAML.load_file(Rails.root.join('config/secrets.yml'))
token = secrets[Rails.env]['secret_token']
if token == 'SOMETHING_RANDOM_HERE'
  raise StandardError.new('You forgot to set the secret token in config/secrets.yml')
else
  OneBody::Application.config.secret_key_base = token
end
