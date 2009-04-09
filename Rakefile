require(File.join(File.dirname(__FILE__), 'config', 'boot'))

require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

require 'tasks/rails'

Dir["#{RAILS_ROOT}/plugins/*/**/tasks/**/*.rake"].sort.each { |ext| load ext }
