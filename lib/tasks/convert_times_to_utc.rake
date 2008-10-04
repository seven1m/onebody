namespace :onebody do

  # Convert an existing sites' dates and times to UTC so that Time Zone support will function properly
  task :convert_times_to_utc => :environment do
  
    # set local time zone below (remove # sign to uncomment)
    # run "rake time:zones:local" or "rake time:zones:all" for a list of time zones
    #Time.zone = 'Central Time (US & Canada)'
    
    raise 'Must set Time.zone in lib/tasks/convert_times_to_utc.rake before running this task.' if Time.zone.name == 'UTC'
    Site.each do
      (Site.sub_models << Site).each do |model|
        puts model.name
        next if [Setting, Tagging, Friendship, FriendshipRequest].include?(model)
        datetime_columns = model.columns.select { |c| c.type == :datetime and !%w(birthday anniversary).include?(c.name) }.map { |c| c.name }
        model.all.each do |record|
          datetime_columns.each do |col|
            record.send("#{col}=", record.send("#{col}_before_type_cast"))
          end
          record.save
        end
      end
    end
  end

end
