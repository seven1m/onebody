# Learn more about this file: http://github.com/javan/whenever

set :environment, 'production'

if File.exist?('config/email.yml')
  every 1.minute do
    settings = YAML::load_file('config/email.yml')[@environment]['pop']
    command "#{Rails.root}/script/inbox -e #{@environment} \"#{settings['host']}\" \"#{settings['username']}\" \"#{settings['password']}\""
  end
end

every 1.minute do
  settings = YAML::load_file('config/database.yml')[@environment]
  command "#{Rails.root}/script/worker -e #{@environment} \"#{settings['host']}\" \"#{settings['username']}\" \"#{settings['password']}\" \"#{settings['database']}\""
end

every 1.hour, :at => 19 do
  runner 'Site.each { Feed.import_all; NewsItem.update_from_feed }'
end

every 1.day, :at => '3:49 am' do
  runner "Site.each { Group.update_memberships; Donortools::Persona.update_all; LogItem.flag_suspicious_activity; GeneratedFile.where(['created_at < ?', 1.day.ago.utc]).each { |f| f.destroy } }; ActiveRecord::SessionStore::Session.delete_all(['updated_at < ?', 1.day.ago.utc])"
end
