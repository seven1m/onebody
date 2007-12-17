namespace 'db' do
  desc 'Add a new Super Admin to the database (invoke with EMAIL=your@address.com)'
  task :add_super_admin => :environment do
    if ENV['EMAIL']
      setting = Setting.find_by_name('Super Admins')
      admins = setting.value
      setting.update_attribute :value, admins << ENV['EMAIL']
      puts 'Super Admin added.'
    else
      puts 'You must invoke this task with an EMAIL argument like this:'
      puts 'rake db:add_super_admin EMAIL=your@address.com'
    end
  end
end