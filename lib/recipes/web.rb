namespace :deploy do
  namespace :web do
    desc 'Copy maintenance page to each web server'
    task :disable, roles: :web, except: { no_release: true } do
      on_rollback { run "rm #{shared_path}/system/maintenance.html" }
      html = File.read(File.join(File.dirname(__FILE__), "templates", "maintenance.html"))
      put html, "#{shared_path}/system/maintenance.html", mode: 0644
    end

    desc 'Remove maintenance page from each web server'
    task :enable, roles: :web, except: { no_release: true } do
      run "rm #{shared_path}/system/maintenance.html"
    end
  end
end
