namespace :deploy do
  task :upload do
    files = (ENV['FILES'] || '').split(',').map { |f| Dir[f.strip] }.flatten
    abort 'Please specify at least one file or directory to update (via the FILES environment variable)' if files.empty?

    on release_roles :all do
      files.each { |file| upload!(file, File.join(current_path, file)) }
    end
  end
end
