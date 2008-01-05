APP_ROOT = File.expand_path(File.join(File.dirname(__FILE__), '..')) unless defined? APP_ROOT

require 'rubygems'
$LOAD_PATH.unshift(File.join(APP_ROOT, '../onebody'))
require 'onebody'

ENV['RAILS_ENV'] = 'production'
