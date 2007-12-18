class AddThemeSetting < ActiveRecord::Migration
  def self.up
    Setting.create(
      :section => 'Appearance',
      :name => 'Theme',
      :value => 'aqueouslight',
      :format => 'string',
      :description => 'Name of selected theme (from themes/ directory).',
      :hidden => false
    )
  end

  def self.down
    setting = Setting.find_by_name('Theme')
    setting.destroy if setting
  end
end
