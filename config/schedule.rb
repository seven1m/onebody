# Learn more about this file: http://github.com/javan/whenever

require 'yaml'

set :environment, 'production'

# the default job_template uses the -i flag, which throws a warning about "no job control"
# without the -i flag, you must ensure your .bashrc doesn't exit at the top due to being non-interactive
# check out the troubleshooting section at http://rvm.beginrescueend.com/rvm/install/ for help
set :job_template, "bash -l -c ':job'"

if File.exist?("#{Dir.pwd}/config/email.yml")
  if settings = YAML::load_file("#{Dir.pwd}/config/email.yml")[@environment]['pop']
    every 1.minute do
      command "#{Dir.pwd}/script/inbox -e #{@environment} \"#{settings['host']}\" \"#{settings['username']}\" \"#{settings['password']}\""
    end
  end
end

every 1.hour, at: 19 do
  runner 'Site.each { NewsItem.update_from_feed }'
end

every 1.day, at: '3:49 am' do
  runner "Site.each { Group.update_memberships; GeneratedFile.stale.destroy_all }"
end
