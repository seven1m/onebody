# Copy the images (*.gif) into RAILS_ROOT/public/images/comatose
RAILS_ROOT = File.join(File.dirname(__FILE__), '../../../')

unless FileTest.exist? File.join(RAILS_ROOT, 'public', 'images', 'comatose')
  FileUtils.mkdir( File.join(RAILS_ROOT, 'public', 'images', 'comatose') )
end

FileUtils.cp( 
  Dir[File.join(File.dirname(__FILE__), 'resources', 'public', 'images', '*.gif')], 
  File.join(RAILS_ROOT, 'public', 'images', 'comatose'),
  :verbose => true
)

# Show the INSTALL text file
puts IO.read(File.join(File.dirname(__FILE__), 'INSTALL'))

