class AddStandaloneUseSetting < ActiveRecord::Migration
  def self.up
    Setting.create(
      :section => 'Features',
      :name => 'Standalone Use',
      :value => true,
      :format => 'boolean',
      :description => "If enabled, OneBody is expected to be your church's main membership database, i.e. you can edit people and family data directly.",
      :hidden => false
    )
  end

  def self.down
    setting = Setting.find_by_name('Standalone Use')
    setting.destroy if setting
  end
end
