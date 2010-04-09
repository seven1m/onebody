begin
  require 'highline/import'
rescue LoadError
  puts 'highline gem not installed'
end

namespace :onebody do
  
  desc 'Create a new (admin) user. Use SITE="Site Name" for multisite.'
  task :new_user => :environment do
    puts 'Create new admin user...'
    Site.current = site = ENV['SITE'] ? Site.find_by_name(ENV['SITE']) : Site.find(1)
    attrs = {
      :email                        => ENV['EMAIL']  ||  ask('Email Address: ') { |q| q.validate = VALID_EMAIL_ADDRESS },
      :first_name                   => ENV['FIRST']  ||  ask('First Name: ')    { |q| q.validate = /.+/ },
      :last_name                    => ENV['LAST']   ||  ask('Last Name: ')     { |q| q.validate = /.+/ },
      :gender                       => ENV['GENDER'] || (ask('Gender ("m" or "f"): ', %w(m f)) { |q| q.case = :down } =~ /^m/ ? 'Male' : 'Female')
    }
    person = site.people.new(attrs)
    if ENV['ENCRYPTED_PASSWORD']
      person.encrypted_password = ENV['ENCRYPTED_PASSWORD']
    elsif ENV['PASSWORD']
      person.password = ENV['PASSWORD']
    else
      password = ask('Password: ') { |q| q.echo = false; q.validate = /.{5,}/ }
      confirm = ask('Password (again): ') { |q| q.echo = false }
      raise 'Passwords do not match.' unless password == confirm
      person.password = password
    end
    person.can_sign_in = true
    person.visible_to_everyone = true
    person.visible_on_printed_directory = true
    person.full_access = true
    person.child = false
    person.salt = ENV['SALT'] if ENV['SALT']
    family = site.families.create!(
      :name => person.name,
      :last_name => person.last_name
    )
    family.people << person
    person.admin = Admin.create!(:super_admin => true)
    person.save!
  end
  
  task :newuser => :new_user do
  end

end
