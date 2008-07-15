module SetupPlugin
  class Routes
    def draw(map)
    
      map.with_options :controller => 'setup/dashboard' do |m|
        m.setup 'setup', :action => 'index'
        m.setup_not_authorized 'setup/not_local_or_secret_not_given', :action => 'not_local_or_secret_not_given'
        m.setup_authorize_ip 'setup/authorize_ip', :action => 'authorize_ip'
        m.setup_change_environment 'setup/change_environment', :action => 'change_environment'
        m.setup_environment 'setup/environment', :action => 'environment'
        m.not_local_or_secret_not_given 'setup/not_local_or_secret_not_given', :action => 'not_local_or_secret_not_given'
      end

      map.with_options :controller => 'setup/sites' do |m|
        m.setup_sites 'setup/sites', :action => 'index'
        m.setup_edit_multisite 'setup/sites/edit_multisite', :action => 'edit_multisite'
        m.setup_edit_site 'setup/sites/edit', :action => 'edit'
        m.setup_delete_site 'setup/sites/delete', :action => 'delete'
      end

      map.with_options :controller => 'setup/database' do |m|
        m.setup_database 'setup/database', :action => 'index'
        m.setup_load_fixtures 'setup/database/load_fixtures', :action => 'load_fixtures'
        m.setup_migrate_database 'setup/database/migrate', :action => 'migrate'
        m.setup_edit_database 'setup/database/edit', :action => 'edit'
        m.setup_backup_database 'setup/database/backup', :action => 'backup'
      end

      map.with_options :controller => 'setup/settings' do |m|
        m.setup_edit_settings 'setup/settings/edit/:id', :action => 'edit'
        m.setup_global_settings 'setup/settings/global', :action => 'global'
        m.setup_settings 'setup/settings/:id', :action => 'view'
      end
      
    end
  end
end
