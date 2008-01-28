require 'highline/import'

namespace :db do
  desc 'Create a new (admin) user. Use SITE="Site Name" for multisite.'
  task :newuser => :environment do
    puts 'Create new admin user...'
    site = ENV['SITE'] ? Site.find_by_name(ENV['SITE']) : Site.find(1)
    Site.current = site # TODO: would be nice if acts_as_scoped_globally could allow bypass of this requirement
    person = site.people.create(
      :email => ask('Email Address: '),
      :first_name => ask('First Name: '),
      :last_name => ask('Last Name: '),
      :password => ask('Password: ') { |q| q.echo = false },
      :password_confirmation => ask('Password (again): ') { |q| q.echo = false },
      :gender => ask('Gender ("m" or "f"): ').downcase == 'm' ? 'Male' : 'Female',
      :can_sign_in => true,
      :visible_to_everyone => true,
      :visible_on_printed_directory => true,
      :full_access => true
    )
    family = site.families.create(
      :name => person.name,
      :last_name => person.last_name
    )
    family.people << person
    admins = site.settings.find_by_name('Super Admins')
    admins.update_attribute :value, admins.value << person.email
  end
end

task :init => [:environment, 'db:create', 'db:migrate'] do
  puts
  Rake::Task['db:newuser'].invoke if agree('Do you want to create a new admin user? ')
  puts
  puts "Now, test your instance by running the following command:"
  puts 'ruby script/server'
  puts
  puts 'Browse to http://localhost:3000'
  puts 'Sign in with the email and password you just entered.'
end

task :update => [:environment, 'db:migrate'] do
  puts
  puts 'System updated.'
end