require "#{File.dirname(__FILE__)}/../test_helper"

class SyncTest < ActionController::IntegrationTest
  #def test_sync
  #  if RAILS_PLATFORM =~ /win32/
  #    `ruby #{File.dirname(__FILE__)}..\..\script\sync test`
  #  else
  #    `#{File.dirname(__FILE__)}../../script/sync test`
  #  end
  #  
  #end
  
  def test_truth
    assert true
  end
end
