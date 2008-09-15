namespace :onebody do
  
  namespace :api do
    
    desc 'Display a super user API key (pass EMAIL arg)'
    task :key => :environment do
      Site.current = site = ENV['SITE'] ? Site.find_by_name(ENV['SITE']) : Site.find(1)
      if ENV['EMAIL']
        if person = Person.find_by_email(ENV['EMAIL'])
          if person.super_admin?
            puts '  Email: ' + person.email
            unless person.api_key
              person.generate_api_key
              person.save
            end
            puts 'API Key: ' + person.api_key
          else
            puts 'Error: The user is not a Super Admin.'
          end
        else
          puts 'Account not found.'
          if Person.count == 0
            puts 'You have no users in the database. First run "rake onebody:newuser"'
          end
        end
      else
        puts 'You must pass EMAIL=your@address.com'
      end
    end
  
  end
  
end
