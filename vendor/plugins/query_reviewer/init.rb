# Include hook code here

require 'query_reviewer'
ActiveRecord::ConnectionAdapters::MysqlAdapter.send(:include, QueryReviewer::MysqlAdapterExtensions)
ActionController::Base.send(:include, QueryReviewer::ControllerExtensions)
Array.send(:include, QueryReviewer::ArrayExtensions)
ActionController::Base.append_view_path(File.dirname(__FILE__) + "/lib/query_reviewer/views") if ActionController::Base.respond_to?(:append_view_path)