#Rake task to populate the default data into the **current environment's database**.
#It can import data from .yml files. The files should be present under "test/fixtures/app_default_data/import" folder.
#Load specific tables using the environment variable "TABLE". Eg:
#=> rake db:fixtures:import TABLE=assessment_components,lookups (Note: There should not be spaces between commas)
#Specific environment using the environment variable "RAILS_ENV"
#=> rake db:fixtures:import TABLE=assessment_components,lookups RAILS_ENV=test
desc "Populates default data reqd. for the app from the fixtures into the current environment's database."
namespace :db  do
  namespace :fixtures do
      task :import => :environment do
	
        require 'active_record/fixtures'
        require 'rake'
        ActiveRecord::Base.establish_connection(RAILS_ENV.to_sym)
        ## set directory to import
        file_base_path = File.join(RAILS_ROOT, 'test/fixtures') ## or File.join(RAILS_ROOT, 'test', 'fixtures')
        puts "importing from: " + file_base_path
	
        puts "the RAILS_ENV is " + RAILS_ENV
	
        if ENV["TABLE"] != nil
            files_array = ENV["TABLE"].to_s.split(",")
        else
            files_array = Dir.glob(File.join(file_base_path, '*.{yml}'))
        end
	
        files_array.each do |fixture_file|
            puts "\n Importing " + File.basename(fixture_file.strip, ".yml") + "..."
            begin
                  if fixture_file.downcase != 'schema_info'
                    Fixtures.create_fixtures(file_base_path, File.basename(fixture_file.strip, '.yml'))
                  else
                    raise   "Not willing to import schema_info!"
                  end
                puts    " Status: Completed"
            rescue
                puts    " Status: Aborted\n\n" + $!
            end
        end
        puts "\nTask completed!"
	
      end
    end
end
	
#Rake task to export data from tables in the current environment db to fixtures (YML format)..
#The files will be exported to "/test/fixtures" folder.
#Export specific tables using the environment variable "TABLE". Eg:
#=> rake db:fixtures:export TABLE=assessment_components,lookups (Note: There should not be spaces between commas)
#Specific environment using the environment variable "RAILS_ENV"
#=> rake db:fixtures:export TABLE=assessment_components,lookups RAILS_ENV=test
	
desc "Export data from tables in the current environment db to fixtures (YML format). "
namespace :db do
  namespace :fixtures do
      task :export => :environment do   
	
        ActiveRecord::Base.establish_connection(RAILS_ENV.to_sym)
        ## set directory to export
        file_base_path = File.join(RAILS_ROOT, 'test/fixtures') ## File.join(RAILS_ROOT, 'test', 'fixtures', 'export')
	
          puts "exporting to: " + file_base_path
        puts "the RAILS_ENV is " + RAILS_ENV
	
        if ENV["TABLE"] != nil
            table_names = ENV["TABLE"].to_s.split(",")
        else
            table_names = ActiveRecord::Base.connection.tables
        end
	
        table_names.each do |table_name|
        if table_name.downcase != 'schema_info'
                puts  "\n Exporting "  + table_name + "... "
                yml_file = "#{file_base_path}/#{table_name}.yml"
                i = "000000"
                File.delete(yml_file) if File.exist?(yml_file)
                File.open(yml_file, 'w' ) do |file_object|
                    begin
                        sql = "SELECT * FROM #{table_name}"
                        data = ActiveRecord::Base.connection.select_all(sql)
                        file_object.write data.inject({}) { |hash, record|
                        hash["#{table_name}_#{i.succ!}"] = record
                        hash
                        }.to_yaml
                    puts    " Status: Completed"
                    rescue
                        puts " Status: Aborted - Table #{table_name} does not exist"
                    end
                end
            end
        end
        puts "\nTask completed!"
	
    end
  end
end