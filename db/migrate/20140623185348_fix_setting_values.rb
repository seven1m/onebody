class FixSettingValues < ActiveRecord::Migration
  def up
    # We used to YAML serialize setting values, but now we don't.
    Setting.all.each do |setting|
      val = YAML.load(setting[:value]) rescue setting[:value]
      val = val.map(&:strip).join("\n") if val.is_a?(Array)
      setting.value = val
      setting.save!
    end
  end
end
