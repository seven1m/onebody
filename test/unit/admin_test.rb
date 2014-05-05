require_relative '../test_helper'

class AdminTest < ActiveSupport::TestCase

  context 'Privileges' do
    should "track available privileges" do
      assert Admin.privileges.include?('view_hidden_profiles')
    end

    should "add privileges" do
      Admin.add_privileges('foo')
      assert Admin.privileges.include?('foo')
    end
  end
end
