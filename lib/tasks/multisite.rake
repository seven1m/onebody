require 'highline/import'

class String
  def ljust!(len)
    self.ljust(len)[0...len]
  end
end

namespace :multisite do
  desc "Enable Multisite feature"
  task :on => :environment do
    Setting.set(nil, 'Features', 'Multisite', true)
  end
  
  desc "Disable Multisite feature"
  task :off => :environment do
    Setting.set(nil, 'Features', 'Multisite', false)
  end
  
  desc "List all sites"
  task :list => :environment do
    puts "Name                Host                Visible Name (from settings)  People"
    puts '-' * 76
    Site.find(:all, :order => 'name').each do |site|
      Site.current = site # TODO: would be nice if acts_as_scoped_globally could allow bypass of this requirement
      puts "#{site.name.ljust!(19)} #{site.host.ljust!(19)} #{site.visible_name.ljust!(29)} #{site.people.count}"
    end
  end
  
  desc "Add a site (NAME and HOST required)"
  task :add => :environment do
    if ENV['NAME'] and ENV['HOST']
      Site.create(:name => ENV['NAME'], :host => ENV['HOST'])
      if agree('Do you want to create a new admin user? ')
        ENV['SITE'] = ENV['NAME']
        Rake::Task['db:newuser'].invoke
      end
    else
      puts 'Usage: rake multsite:add NAME="Second Site" HOST=site2.example.com'
    end
  end
  
  desc "Delete a site (NAME required)"
  task :delete => :environment do
    if ENV['NAME']
      if site = Site.find_by_name(ENV['NAME']) and site.id != 1
        Site.current = site # TODO: would be nice if acts_as_scoped_globally could allow bypass of this requirement
        puts "Site:         #{site.name}"
        puts "Host:         #{site.host}"
        puts "Visible Name: #{site.visible_name}"
        puts "Stats:"
        puts " families:    #{site.families.count}"
        puts " people:      #{site.people.count}"
        puts " groups:      #{site.groups.count}"
        puts " verses:      #{site.verses.count}"
        puts
        if agree('Are you sure you want to delete this site and ALL its data? ')
          site.destroy_for_sure
          puts 'Site deleted.'
        end
      elsif site.id == 1
        raise 'You cannot delete the default site (ID=1).'
      else
        raise 'No site found with NAME ' + ENV['NAME']
      end
    else
      puts 'Usage: rake multsite:add NAME="Second Site" HOST=site2.example.com'
    end
  end
  
  desc "Modify a site (NAME, NEW_NAME, NEW_HOST required)"
  task :modify => :environment do
    if ENV['NAME'] and ENV['NEW_NAME'] and ENV['NEW_HOST']
      if site = Site.find_by_name(ENV['NAME'])
        site.update_attributes! :name => ENV['NEW_NAME'], :host => ENV['NEW_HOST']
      else
        raise 'No site found with NAME ' + ENV['NAME']
      end
    else
      puts 'Usage: rake multsite:modify NAME="Second Site" NEW_NAME="Site 2" NEW_HOST=site2.com'
    end
  end
end