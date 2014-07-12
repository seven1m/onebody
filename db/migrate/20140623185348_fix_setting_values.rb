class FixSettingValues < ActiveRecord::Migration
  def up
    # We used to YAML serialize setting values, but now we don't.
    Setting.all.each do |setting|
      begin
        val = YAML.load(setting[:value])
      rescue Psych::SyntaxError # not sure why we have to rescue this error by itself
        val = setting[:value]
      rescue
        val = setting[:value]
      end
      val = val.map(&:strip).join("\n") if val.is_a?(Array)
      setting.value = val
      setting.save!
    end
  end
end
