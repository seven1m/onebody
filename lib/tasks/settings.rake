begin
  require 'highline/import'
rescue LoadError
  puts 'highline gem not installed'
end

namespace :onebody do

  def print_setting_value(setting, label='Value:')
    if setting.format == 'list'
      puts label
      puts setting.value.join("\n")
    else
      puts "#{label} #{setting.value}"
    end
  end

  task :settings => :environment do
    sites = Site.all(:order => 'id')
    site_choices = ['0'] + sites.map { |s| s.id.to_s }
    loop do
      puts
      puts 'Choose a site (or choose to modify global settings):'
      puts '  0. Global Settings'
      sites.each do |site|
        puts "#{site.id.to_s.rjust(3)}. #{site.name[0..70]}"
      end
      puts '  q. Quit'
      site_selection = ask('Selection: ', site_choices + ['q']) { |q| q.case = :down }
      break if site_selection == 'q'
      
      if site_selection == '0'
        site = nil
      else
        site = Site.find(site_selection)
      end
      loop do
        puts
        puts 'Choose a section:'
        sections = Setting.where(sql: if site
  ["select distinct section from settings where site_id = ?", site.id]
else
  ["select distinct section from settings where global = ?", true]
end).first.map do |section|
          section.section
        end
        section_selection = choose(*(sections + ['(back)'])) { |q| q.flow = :columns_down }
        break if section_selection == '(back)'
        
        loop do
          puts
          puts 'Choose a setting:'
          if site
            settings = Setting.where(site_id: site.id, section: section_selection).all.map { |s| s.name }
          else
            settings = Setting.where(global: true, section: section_selection).all.map { |s| s.name }
          end
          setting_selection = choose(*settings + ['(back)']) { |q| q.flow = :columns_down }
          break if setting_selection == '(back)'

          if site
            setting = Setting.where(site_id: site.id, section: section_selection, name: setting_selection).first
          else
            setting = Setting.where(global: true, section: section_selection, name: setting_selection).first
          end       
          puts
          puts "Setting - #{setting.section}: #{setting.name}"
          print_setting_value(setting)
          puts
          if ask('Change value? (y/n) ', %w(y n)) == 'y'
            case setting.format
              when 'boolean'
                puts 'Enter 1 for true/enabled, 0 for false/disabled'
                value = ask('Value: ', %w(0 1))
              when 'list'
                puts 'One value per line, enter a blank line to stop.'
                value = []
                loop do
                  v = ask('Value: ')
                  value << v if v.any?
                  break unless v.any?
                end
              else
                value = ask('Value: ')
            end
            setting.value = value
            setting.save
            print_setting_value(setting, 'Updated Value:')
            puts 'Setting updated.'
          end
          
        end
      end
    end
  end
  
end
