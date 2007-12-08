namespace :comatose do
  #
  # Setup Task...
  #
  namespace :setup do
    
    desc "If the installation didn't add the images correctly, use this task"
    task :copy_images do
      plugin_dir = File.join(File.dirname(__FILE__), '..')
      unless FileTest.exist? File.join(RAILS_ROOT, 'public', 'images', 'comatose')
        FileUtils.mkdir( File.join(RAILS_ROOT, 'public', 'images', 'comatose') )
      end
      FileUtils.cp( 
        Dir[File.join(plugin_dir, 'resources', 'public', 'images', '*.gif')], 
        File.join(RAILS_ROOT, 'public', 'images', 'comatose'),
        :verbose => true
      )
      puts "Finished."
    end
    
    # For use when upgrading...
    
    def move(args)
      if ENV['USE_SVN'] == 'true'
        `svn move #{args}`
      else
        `mv #{args}`
      end
    end
    
    def delete(args)
      if ENV['USE_SVN'] == 'true'
        `svn delete #{args}`
      else
        `rm -rf #{args}`
      end
    end
    
    # TODO: Test the setup:restructure_customization task...
    desc "[EXPERIMENTAL] Restructures customized admin folder to version 0.6 from older version -- Only run this if you have customized the admin. USE_SVN=true if you want to update subversion"
    task :restructure_customization do
      ENV['USE_SVN'] ||= 'false'
      move 'public/javscripts/comatose.js public/javscripts/comatose_admin.js' 
      move 'public/stylesheets/comatose.css public/stylesheets/comatose_admin.css' 
      move 'app/views/comatose app/views/comatose_admin' 
      delete 'app/views/layouts/comatose_content.rhtml' 
    end
  end
end