namespace :onebody do

  namespace :export do
  
    namespace :people do
    
      desc 'Export OneBody people data as XML file (pass FILE argument)'
      task :xml => :environment do
        Site.current = site = ENV['SITE'] ? Site.find_by_name(ENV['SITE']) : Site.find(1)
        if ENV['FILE']
          people = Person.all(:order => 'last_name, first_name, suffix')
          File.open(ENV['FILE'], 'w') do |file|
            file.write people.to_xml(:read_attribute => true, :except => %w(feed_code encrypted_password salt api_key site_id), :include => [:groups, :family])
          end
        else
          puts 'You must specify the output file path, e.g. FILE=people.xml'
        end
      end
      
      desc 'Export OneBody people data as CSV file (pass FILE argument)'
      task :csv => :environment do
        Site.current = site = ENV['SITE'] ? Site.find_by_name(ENV['SITE']) : Site.find(1)
        if ENV['FILE']
          people = Person.all(:order => 'last_name, first_name, suffix')
          File.open(ENV['FILE'], 'w') do |file|
            file.write people.to_csv(:read_attribute => true, :except => %w(feed_code encrypted_password salt api_key site_id), :include => [:family])
          end
        else
          puts 'You must specify the output file path, e.g. FILE=people.csv'
        end
      end
    
    end
  
  end

end
