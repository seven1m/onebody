namespace :db do
  task :newuser => :environment do
    require 'highline/import'
    puts
    puts 'Create the initial admin user...'
    person = Person.create(
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
    family = Family.create(
      :name => person.name,
      :last_name => person.last_name
    )
    family.people << person
    Setting.find_by_name('Super Admins').update_attribute :value, [person.email]
  end
end

task :init => [:environment, 'db:create', 'db:migrate', 'db:newuser'] do
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