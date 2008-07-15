require File.dirname(__FILE__) + '/../../config/environment'
require File.dirname(__FILE__) + '/migration.rb'
CheckinMigration.up
File.open(File.dirname(__FILE__) + '/enable', 'w') { |f| f.write('plugin enabled') }
