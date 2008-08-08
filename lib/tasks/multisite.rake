begin
  require 'highline/import'
rescue LoadError
  puts 'highline gem not installed'
end

class String
  def ljust!(len)
    self.ljust(len)[0...len]
  end
end

namespace :onebody do

  task :sites => :environment do
    if Setting.get(:features, :multisite)
      puts "Name              Host              Visible Name (in settings)  People Active"
      puts '-' * 77
      Site.each do |site|
        puts "#{site.name.ljust!(17)} #{site.host.to_s.ljust!(17)} #{site.visible_name.to_s.ljust!(27)} #{site.people.count.to_s.ljust(6)} #{site.active? ? 'yes' : 'no'}"
      end
    else
      puts 'Multiple sites feature is disabled. Run rake onebody:sites:on to enable.'
    end
  end

  namespace :sites do
    desc "Enable multiple sites"
    task :on => :environment do
      Setting.set(nil, 'Features', 'Multisite', true)
      puts 'Multiple sites can now be hosted.'
    end
    
    desc "Disable multiple sites"
    task :off => :environment do
      Setting.set(nil, 'Features', 'Multisite', false)
      puts 'Multiple sites feature disabled. Default site will answer for all requests now.'
    end
    
    desc "Add a site"
    task :add => :environment do
      if ENV['NAME'] and ENV['HOST']
        args = site_args(:name => ENV['NAME'], :host => ENV['HOST'])
        Site.create!(args)
        Rake::Task['onebody:sites'].invoke
      else
        puts 'Usage: rake onebody:sites:add NAME="Second Site" HOST=site2.example.com'
      end
    end
    
    desc "Delete a site"
    task :delete => :environment do
      if ENV['NAME']
        if site = Site.find_by_name(ENV['NAME']) and site.id != 1
          Site.current = site
          puts "Site:         #{site.name}"
          puts "Host:         #{site.host}"
          puts "Visible Name: #{site.visible_name}"
          puts "Stats:"
          puts " families:    #{site.families.count}"
          puts " people:      #{site.people.count}"
          puts " groups:      #{site.groups.count}"
          puts " verses:      #{site.verses.count}"
          puts
          if ENV['SURE'] or agree('Are you sure you want to delete this site and ALL its data? ')
            site.destroy_for_sure
            Rake::Task['onebody:sites'].invoke
          else
            puts 'aborted'
          end
        elsif site.id == 1
          raise 'You cannot delete the default site (ID=1).'
        else
          raise 'No site found with NAME ' + ENV['NAME']
        end
      else
        puts 'Usage: rake onebody:sites:add NAME="Second Site" HOST=site2.example.com'
      end
    end
    
    desc "Modify a site"
    task :modify => :environment do
      if ENV['NAME']
        if site = Site.find_by_name(ENV['NAME'])
          args = {}
          args['name'] = ENV['NEW_NAME'] unless ENV['NEW_NAME'].nil?
          args['host'] = ENV['HOST'] unless ENV['HOST'].nil?
          args = site_args(args)
          site.update_attributes!(args)
          Rake::Task['onebody:sites'].invoke
        else
          raise 'No site found with NAME ' + ENV['NAME']
        end
      else
        puts 'Usage: rake onebody:sites:modify NAME="Second Site" NEW_NAME="Site 2" HOST=site2.com'
      end
    end
    
    desc "Activate a site"
    task :activate => :environment do
      if ENV['NAME'] and site = Site.find_by_name(ENV['NAME']) and site.id != 1
        site.update_attributes!(:active => true)
        Rake::Task['onebody:sites'].invoke
      else
        puts 'Usage: rake onebody:sites:activate NAME="Second Site"'
        puts '(you cannot activate/deactivate the default site)'
      end
    end
    
    desc "Deactivate a site"
    task :deactivate => :environment do
      if ENV['NAME'] and site = Site.find_by_name(ENV['NAME']) and site.id != 1
        site.update_attributes!(:active => false)
        Rake::Task['onebody:sites'].invoke
      else
        puts 'Usage: rake onebody:sites:deactivate NAME="Second Site"'
        puts '(you cannot activate/deactivate the default site)'
      end
    end
    
    def site_args(args={})
      %w(secondary_host max_admins max_people max_groups).each { |a| args[a] = ENV[a.upcase] unless ENV[a.upcase].nil? }
      %w(import_export_enabled pages_enabled pictures_enabled publications_enabled).each do |arg|
        args[arg] = %w(true yes on).include?(ENV[arg.upcase].downcase) unless ENV[arg.upcase].nil?
      end
      args
    end
  end
end
