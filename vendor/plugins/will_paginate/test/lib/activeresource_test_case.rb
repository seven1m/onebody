Dir.glob( File.join(File.dirname(__FILE__), '..', 'fixtures', 'client', '**', '*.rb') ) {|file| require file }

require 'active_resource/http_mock'

require 'will_paginate'
WillPaginate.enable_activeresource
