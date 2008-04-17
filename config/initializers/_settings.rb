if RAILS_ENV == 'test'
  %w(settings sites).each do |file|
    model = eval(file.singularize.classify)
    next unless model.table_exists?
    YAML::load(File.open(File.join(RAILS_ROOT, "test/fixtures/#{file}.yml"))).each do |fixture, values|
      model.create(values)
    end
  end
  Site.current = Site.find(1) if Site.table_exists?
end
