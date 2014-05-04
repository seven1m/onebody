# Learn more about this file: http://github.com/javan/whenever

set :environment, 'production'

# the default job_template uses the -i flag, which throws a warning about "no job control"
# without the -i flag, you must ensure your .bashrc doesn't exit at the top due to being non-interactive
# check out the troubleshooting section at http://rvm.beginrescueend.com/rvm/install/ for help
set :job_template, "bash -l -c ':job'"

if File.exist?("#{Dir.pwd}/config/email.yml")
  every 1.minute do
    settings = YAML::load_file('config/email.yml')[@environment]['pop']
    command "#{Dir.pwd}/script/inbox -e #{@environment} \"#{settings['host']}\" \"#{settings['username']}\" \"#{settings['password']}\""
  end
end

every 1.minute do
  yaml = YAML::load_file("#{Dir.pwd}/config/database.yml")
  settings = yaml[@environment]
  if settings.is_a?(String) and %w(production development).include?(settings)
    settings = yaml[settings]
  end
  command "#{Dir.pwd}/script/worker -e #{@environment} \"#{settings['host']}\" \"#{settings['username']}\" \"#{settings['password']}\" \"#{settings['database']}\""
end

every 1.hour, :at => 19 do
  runner 'Site.each { NewsItem.update_from_feed }'
end

every 1.day, :at => '3:49 am' do
  runner "Site.each { Group.update_memberships; Donortools::Persona.update_all; LogItem.flag_suspicious_activity; GeneratedFile.where(['created_at < ?', 1.day.ago.utc]).each { |f| f.destroy } }; ActiveRecord::SessionStore::Session.delete_all(['updated_at < ?', 1.day.ago.utc])"
end
