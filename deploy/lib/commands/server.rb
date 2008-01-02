require 'active_support'
require 'fileutils'
%w(cache pids sessions sockets).each { |dir_to_make| FileUtils.mkdir_p(File.join(APP_ROOT, 'tmp', dir_to_make)) }
require APP_ROOT + "/lib/commands/servers/webrick"
