# Learn more about this file: http://github.com/javan/whenever

require 'yaml'

set :environment, 'production'

# the default job_template uses the -i flag, which throws a warning about "no job control"
# without the -i flag, you must ensure your .bashrc doesn't exit at the top due to being non-interactive
# check out the troubleshooting section at http://rvm.beginrescueend.com/rvm/install/ for help
set :job_template, "bash -l -c ':job'"

root_path = File.expand_path('../../', __FILE__)
email_config_path = File.expand_path('../email.yml', __FILE__)
inbox_cmd = ENV['APP_HOME'] == '/opt/onebody' ? 'onebody run script/inbox' : "#{root_path}/script/inbox"
runner_cmd = ENV['APP_HOME'] == '/opt/onebody' ? 'onebody run rails runner' : "cd #{root_path} && bin/rails runner"

if File.exist?(email_config_path)
  config = YAML.load_file(email_config_path)
  if config.is_a?(Hash) && config[@environment] && (settings = config[@environment]['pop'])
    every 1.minute do
      command "#{inbox_cmd} -e #{@environment} #{settings['host'].inspect} #{settings['username'].inspect} #{settings['password'].inspect}"
    end
  end
end

every 1.hour, at: 19 do
  command "#{runner_cmd} 'Site.each { NewsItem.update_from_feed }'"
end

every 1.day, at: '3:49 am' do
  command "#{runner_cmd} 'Site.each { Group.update_memberships; GeneratedFile.stale.destroy_all }'"
end
