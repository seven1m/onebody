# Learn more about this file: http://github.com/javan/whenever

set :environment, 'production_lite'

if File.exist?('config/email.yml')
  every 1.minute do
    settings = YAML::load_file('config/email.yml')['production']['pop']
    command "#{Rails.root}/script/inbox -e #{@environment} \"#{settings['host']}\" \"#{settings['username']}\" \"#{settings['password']}\""
  end
end

every 1.hour, :at => 19 do
  runner 'Site.each { Feed.import_all; NewsItem.update_from_feed }'
end

every 1.day, :at => '3:49 am' do
  runner "ActionController::Session::ActiveRecordStore::Session.delete_all(['updated_at < ?', 1.day.ago.utc]); Site.each { Group.update_memberships; LogItem.flag_suspicious_activity }"
end
