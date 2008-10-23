namespace :onebody do
  desc 'Load sample data into the database.'
  task :load_sample_data do
    Rake::Task['onebody:build_settings_fixture_file'].invoke
    Rake::Task['db:fixtures:load'].invoke
    Site.each do |site|
      site.add_pages # reload Help pages
    end
  end
end
