begin
  require 'highline/import'
rescue LoadError
  puts 'highline gem not installed'
end

class String
  def ljust!(len)
    ljust(len)[0...len]
  end
end

namespace :onebody do
  task sites: :environment do
    if Setting.get(:features, :multisite)
      puts 'ID  Name                                      Host                       Active'
      puts '-' * 79
      Site.each do |site|
        puts "#{site.id.to_s.ljust(3)} #{site.name.ljust!(41)} #{site.host.to_s.ljust!(26)} #{site.active? ? 'yes' : 'no'}"
      end
    else
      puts 'Multiple sites feature is disabled. Run rake onebody:sites:on to enable.'
    end
  end

  namespace :sites do
    desc 'Enable multiple sites'
    task on: :environment do
      Setting.set(nil, 'Features', 'Multisite', true)
      puts 'Multiple sites can now be hosted.'
    end

    desc 'Disable multiple sites'
    task off: :environment do
      Setting.set(nil, 'Features', 'Multisite', false)
      puts 'Multiple sites feature disabled. Default site will answer for all requests now.'
    end

    desc 'Display stats about a site'
    task show: :environment do
      if ENV['NAME'] || ENV['ID']
        site = ENV['NAME'] ? Site.where(name: ENV['NAME']).first : Site.where(id: ENV['ID']).first
        if Site.current = site
          puts "Site:         #{site.name}"
          puts "Host:         #{site.host}"
          puts "Visible Name: #{site.visible_name}"
          puts 'Stats:'
          puts " families:    #{site.families.count}"
          puts " people:      #{site.people.count}"
          puts " groups:      #{site.groups.count}"
          puts " verses:      #{site.verses.count}"
        else
          puts 'Site not found.'
        end
      else
        puts 'Please specify either NAME or ID.'
      end
    end

    desc 'Add a site'
    task add: :environment do
      if ENV['NAME'] && ENV['HOST']
        args = site_args(name: ENV['NAME'], host: ENV['HOST'])
        Site.create!(args)
        Rake::Task['onebody:sites'].invoke
      else
        puts 'Usage: rake onebody:sites:add NAME="Second Site" HOST=site2.example.com'
      end
    end

    desc 'Delete a site'
    task delete: :environment do
      if ENV['NAME'] || ENV['ID']
        site = ENV['NAME'] ? Site.where(name: ENV['NAME']).first : Site.where(id: ENV['ID']).first
        if site && !site.default?
          Rake::Task['onebody:sites:show'].invoke
          Site.current = site
          if ENV['SURE'] || agree('Are you sure you want to delete this site and ALL its data? ')
            site.destroy_for_real
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
        puts 'Usage: rake onebody:sites:delete NAME="Second Site"'
      end
    end

    desc 'Modify a site'
    task modify: :environment do
      if ENV['NAME'] || ENV['ID']
        site = ENV['NAME'] ? Site.where(name: ENV['NAME']).first : Site.where(id: ENV['ID']).first
        if site
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

    desc 'Activate a site'
    task activate: :environment do
      if ENV['NAME'] || ENV['ID']
        site = ENV['NAME'] ? Site.where(name: ENV['NAME']).first : Site.where(id: ENV['ID']).first
        if site && !site.default?
          site.update_attributes!(active: true)
          Rake::Task['onebody:sites'].invoke
        else
          puts 'Usage: rake onebody:sites:activate NAME="Second Site"'
          puts '(you cannot activate/deactivate the default site)'
        end
      else
        puts 'Please specify either NAME or ID.'
      end
    end

    desc 'Deactivate a site'
    task deactivate: :environment do
      if ENV['NAME'] || ENV['ID']
        site = ENV['NAME'] ? Site.where(name: ENV['NAME']).first : Site.where(id: ENV['ID']).first
        if site && !site.default?
          site.update_attributes!(active: false)
          Rake::Task['onebody:sites'].invoke
        else
          puts 'Usage: rake onebody:sites:deactivate NAME="Second Site"'
          puts '(you cannot activate/deactivate the default site)'
        end
      else
        puts 'Please specify either NAME or ID.'
      end
    end

    def site_args(args = {})
      %w(secondary_host max_admins max_people max_groups).each do |arg|
        args[arg] = (ENV[arg.upcase] == '' ? nil : ENV[arg.upcase]) unless ENV[arg.upcase].nil?
      end
      %w(import_export_enabled pages_enabled pictures_enabled active).each do |arg|
        args[arg] = %w(true yes on).include?(ENV[arg.upcase].downcase) unless ENV[arg.upcase].nil?
      end
      args
    end
  end
end
