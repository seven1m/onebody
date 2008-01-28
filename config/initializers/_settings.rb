if RAILS_ENV == 'test'
  %w(settings sites).each do |file|
    YAML::load(File.open(File.join(RAILS_ROOT, "test/fixtures/#{file}.yml"))).each do |fixture, values|
      eval(file.singularize.classify).create(values)
    end
  end
  Site.current = Site.find(1)
end
