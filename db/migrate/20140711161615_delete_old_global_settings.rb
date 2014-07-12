class DeleteOldGlobalSettings < ActiveRecord::Migration
  def change
    Setting.where(global: true).each do |setting|
      unless Setting::GLOBAL_SETTINGS.include?("#{setting.section}.#{setting.name}")
        setting.destroy
      end
    end
  end
end
