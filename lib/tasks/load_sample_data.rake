namespace :onebody do
  desc 'Load sample data into the database.'
  task :load_sample_data do
    Rake::Task['db:fixtures:load'].invoke
    # reload Help pages
    require Rails.root + "/db/migrate/20080722143227_move_system_content_to_pages"
    MoveSystemContentToPages.up
  end
end
