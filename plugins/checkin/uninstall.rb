require File.dirname(__FILE__) + '/../../config/environment'
require File.dirname(__FILE__) + '/migration.rb'
CheckinMigration.down
File.delete(File.dirname(__FILE__) + '/enable')
