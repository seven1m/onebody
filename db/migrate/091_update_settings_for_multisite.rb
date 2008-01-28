class UpdateSettingsForMultisite < ActiveRecord::Migration
  def self.up
    # create Multisite setting
    Setting.create(:section => 'Features', :name => 'Multisite', :value => false, :format => 'boolean', :description => 'When enabled, this instance can handle multiple sites, based on domain name.')
    # update settings to allow for global settings
    add_column :settings, :global, :boolean, :default => false
    Setting.reset_column_information
    Setting::GLOBAL_SETTINGS.each do |setting|
      section, name = setting.split('.')
      Setting.find_by_section_and_name(section, name).update_attributes! :global => true, :site_id => nil
    end
    # remove some unnecessary settings
    Setting.delete('Contact', 'System Noreply Email')
  end

  def self.down
    remove_column :settings, :global
    Setting.create(:section => 'Contact', :name => 'System Noreply Email', :value => 'no-reply@imaginaryfamily.com', :description => 'Email address where some email is sent (email that does not allow replies)', :format => 'string')
    Setting.delete('Features', 'Multisite')
  end
end
