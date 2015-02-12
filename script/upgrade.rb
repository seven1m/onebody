class String
def green; "\033[32m#{self}\033[0m" end
def red;   "\033[31m#{self}\033[0m" end
end

puts("How to upgrade guide".green)
puts("Check latest releases at https://github.com/churchio/onebody/releases and select version to upgrade.")
puts("1: upgrade from 3.3.0 to 3.4.0\n")
puts("2: upgrade from 3.2.0 to 3.3.0\n")
puts("3: upgrade from 3.1.0 to 3.2.0\n")
puts("4: upgrade from 3.0.0 to 3.1.0\n")
puts("Please select version you would like to upgrade(1/2/3/4): ")
input = gets.chomp
if input == '1' || input == "1." then
	puts("\nRun commands in this order:\n")
	puts("cd /var/www/onebody\n".green)
	puts("git fetch origin\n".green)
	puts("git checkout 3.4.0\n".green)
	puts("bundle install\n".green)
	puts("RAILS_ENV=production bundle exec rake db:migrate\n".green)
	puts("RAILS_ENV=production bundle exec rake tmp:clear assets:precompile\n".green)
	puts("touch tmp/restart.txt\n".green)
	puts("This is the first version that started using bundle install instead of bundle install --deployment. To make this work:\n")
	puts("rm -rf /var/www/onebody/vendor/bundle\n".green)
	puts("So Rails can find the gems.\n")
end
if input == '2' || input == "2." then
	puts("\nRun commands in this order:\n")
	puts("cd /var/www/onebody\n".green)
	puts("git fetch origin\n".green)
	puts("git checkout 3.4.0\n".green)
	puts("bundle install\n".green)
	puts("RAILS_ENV=production bundle exec rake db:migrate\n".green)
	puts("RAILS_ENV=production bundle exec rake tmp:clear assets:precompile\n".green)
	puts("touch tmp/restart.txt\n".green)
end
if input == '3' || input == "3." then
	puts("Be sure you are upgrading from version 3.0.0 or later. If you are upgrading from version 2.x, you have to first completely upgrade to 3.0.0\n".red)
	puts("\nRun commands in this order:\n")
	puts("cd /var/www/onebody\n".green)
	puts("git fetch origin\n".green)
	puts("git checkout 3.4.0\n".green)
	puts("bundle install\n".green)
	puts("RAILS_ENV=production bundle exec rake db:migrate\n".green)
	puts("RAILS_ENV=production bundle exec rake tmp:clear assets:precompile\n".green)
	puts("touch tmp/restart.txt\n".green)
	puts("Set your \"Default Country\" in the admin dashboard Settings screen.\n")
	puts("Run the following rake task to set your country on all existing family records:\n")
	puts("RAILS_ENV=production bundle exec rake onebody:set_country\n".green)
end
if input == '4' || input == "4." then
	puts("\nRun commands in this order:\n")
	puts("cd /var/www/onebody\n".green)
	puts("git fetch origin\n".green)
	puts("git checkout 3.4.0\n".green)
	puts("bundle install\n".green)
	puts("RAILS_ENV=production bundle exec rake db:migrate\n".green)
	puts("RAILS_ENV=production bundle exec rake tmp:clear assets:precompile\n".green)
	puts("touch tmp/restart.txt\n".green)
	puts("Add \"secret_key_base\" to your \"secrets.yml\" file. Example: \nhttps://github.com/churchio/onebody/blob/master/config/secrets.yml.example\n")
end

