namespace :onebody do

  namespace :export do

    desc 'Export the SQL for a single site (pass SITE_ID and OUT_FILE arguments)'
    task :site => :environment do
      db = Rails::Configuration.new.database_configuration[Rails.env]
      if ENV['SITE_ID'] and ENV['OUT_FILE']
        db_and_credentials = "-u#{db['username']} -p#{db['password']} #{db['database']}"
        `mysqldump \\
          --single-transaction \\
          --ignore-table=#{db['database']}.people_verses \\
          --ignore-table=#{db['database']}.admins_reports \\
          --ignore-table=#{db['database']}.schema_migrations \\
          --ignore-table=#{db['database']}.sessions \\
          --ignore-table=#{db['database']}.signin_failures \\
          --ignore-table=#{db['database']}.sites \\
          --ignore-table=#{db['database']}.taggings \\
          -w"site_id = #{ENV['SITE_ID']}" \\
          #{db_and_credentials} \\
          > #{ENV['OUT_FILE']}`
        `mysqldump \\
          --single-transaction \\
          -w"person_id in (select id from people where site_id=#{ENV['SITE_ID']})" \\
          #{db_and_credentials} people_verses \\
          >> #{ENV['OUT_FILE']}`
        `mysqldump \\
          --single-transaction \\
          -w"tag_id in (select id from tags where site_id=#{ENV['SITE_ID']})" \\
          #{db_and_credentials} taggings \\
          >> #{ENV['OUT_FILE']}`
        `mysqldump \\
          --single-transaction \\
          -w"admin_id in (select id from admins where site_id=#{ENV['SITE_ID']})" \\
          #{db_and_credentials} admins_reports \\
          >> #{ENV['OUT_FILE']}`
        `mysqldump \\
          --single-transaction \\
          -w"id=#{ENV['SITE_ID']}" \\
          #{db_and_credentials} sites \\
          >> #{ENV['OUT_FILE']}`
      else
        puts 'Must specify SITE_ID and OUT_FILE arguments'
      end
    end

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
            file.write people.to_csv_mine(:read_attribute => true, :except => %w(feed_code encrypted_password salt api_key site_id), :include => [:family])
          end
        else
          puts 'You must specify the output file path, e.g. FILE=people.csv'
        end
      end

    end

  end

end
