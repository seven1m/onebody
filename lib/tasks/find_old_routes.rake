# Aide in finding invalid url generation via old (removed) named routes.

task :find_old_routes do
  
  named_routes = `cd #{File.dirname(__FILE__)}/../.. && rake routes`.split(/\n/).map { |r| r.strip.split.first }.reject { |r| %w(GET PUT POST DELETE).include? r }.join("\n")
  
  ignore = %w(file job update_view expand secret_file full_picture large_picture medium_picture small_picture google walmart yahoo amazon image_small image_medium image_large image reply original jpg eps simple get_version_from object object_image)
  
  Dir[File.dirname(__FILE__) + '/../../app/**/*'].each do |filename|
    unless File.directory?(filename)
      code = File.read(filename)
      code.scan(/([a-z_]+)_(path|url)/).map { |r| r.first }.reject { |r| ignore.include? r }.uniq.each do |r|
        unless named_routes.include?(r)
          puts filename.split('app/').last
          puts '  ' + r
        end
      end
    end
  end
  
end
