namespace :onebody do
  desc 'Set the Country field on every family in the database (optionally pass SITE_ID)'
  task set_country: :environment do
    Site.current = ENV['SITE_ID'] ? Site.find(ENV['SITE_ID']) : Site.find(1)
    to_update = Family.where("coalesce(country, '') = ''")
    print "updating #{to_update.count} record(s)..."
    to_update.update_all(country: Setting.get(:system, :default_country))
    puts 'done.'
  end
end
