app_root = File.expand_path(File.dirname(__FILE__) + '/app')

load_paths.each do |path|
  Dependencies.load_once_paths.delete(path)
end
