class AddGendersAndSuffixesSettings < ActiveRecord::Migration
  def self.up
    Setting.create(
      :section => 'System',
      :name => 'Genders',
      :value => %w(Male Female Boy Girl),
      :format => 'list',
      :description => "",
      :hidden => true
    )
    Setting.create(
      :section => 'System',
      :name => 'Suffixes',
      :value => %w(Jr. Sr. II III),
      :format => 'list',
      :description => "",
      :hidden => false
    )
  end

  def self.down
    setting = Setting.find_by_name('Genders')
    setting.destroy if setting
    setting = Setting.find_by_name('Suffixes')
    setting.destroy if setting
  end
end
