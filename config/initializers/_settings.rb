if Rails.env.test? and ActiveRecord::Base.connected?
  %w(settings sites).each do |file|
    model = eval(file.singularize.classify)
    next unless model.table_exists?
    path = Rails.root.join("test/fixtures/#{file}.yml")
    if File.exist?(path)
      YAML::load(File.open(path)).each do |fixture, values|
        model.create(values)
      end
    end
  end
end

SETTINGS = {}

Setting.update_all if Setting.table_exists?
