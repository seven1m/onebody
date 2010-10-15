if Rails.env.test? and ActiveRecord::Base.connected?
  %w(settings sites).each do |file|
    model = eval(file.singularize.classify)
    next unless model.table_exists?
    path = File.join(RAILS_ROOT, "test/fixtures/#{file}.yml")
    if File.exist?(path)
      YAML::load(File.open(path)).each do |fixture, values|
        model.create(values)
      end
    end
  end
  Site.current = Site.find(1) if Site.table_exists?
end

SETTINGS = {}
