begin
  require 'highline/import'
rescue LoadError
  puts 'highline gem not installed'
end

namespace :onebody do
  
  desc 'Initialize database'
  task :init => [:environment, 'db:create', 'db:migrate'] do
    puts
    new_user = agree('Do you want to create a new admin user? ')
    Rake::Task['onebody:newuser'].invoke if new_user
    puts
    puts "Now, test your instance by running the following command:"
    puts 'ruby script/server'
    puts
    puts 'Browse to http://localhost:3000'
    puts 'Sign in with the email and password you just entered.' if new_user
  end

  desc 'Update database and settings.'
  task :update => [:environment, 'db:migrate', 'onebody:settings:update'] do
    puts
    puts 'System updated.'
  end
  
  namespace :settings do
    desc 'Updates all settings'
    task :update do
      Setting.update_all
    end
  end
  
  desc 'Create a new (admin) user. Use SITE="Site Name" for multisite.'
  task :newuser => :environment do
    puts 'Create new admin user...'
    Site.current = site = ENV['SITE'] ? Site.find_by_name(ENV['SITE']) : Site.find(1)
    unless password = ENV['PASSWORD'] or encrypted_password = ENV['ENCRYPTED_PASSWORD']
      password = ask('Password: ')         { |q| q.echo = false }
      confirm  = ask('Password (again): ') { |q| q.echo = false }
      raise 'Passwords do not match.' unless password == confirm
    end
    unless gender = ENV['GENDER']
      gender = ask('Gender ("m" or "f"): ').downcase == 'm' ? 'Male' : 'Female'
    end
    attrs = {
      :email                        => ENV['EMAIL'] || ask('Email Address: '),
      :first_name                   => ENV['FIRST'] || ask('First Name: '),
      :last_name                    => ENV['LAST']  || ask('Last Name: '),
      :gender                       => gender,
      :can_sign_in                  => true,
      :visible_to_everyone          => true,
      :visible_on_printed_directory => true,
      :full_access                  => true
    }
    attrs[:password] = password if password
    attrs[:encrypted_password] = encrypted_password if encrypted_password
    person = site.people.create!(attrs)
    family = site.families.create!(
      :name => person.name,
      :last_name => person.last_name
    )
    family.people << person
    admins = site.settings.find_by_name('Super Admins')
    admins.update_attributes! :value => [person.email]
  end

end
