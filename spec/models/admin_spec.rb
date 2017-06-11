require_relative '../rails_helper'

describe Admin do
  describe 'Privileges' do
    it 'should track available privileges' do
      expect(Admin.privileges).to include('view_hidden_profiles')
    end

    it 'should add privileges' do
      Admin.add_privileges('foo')
      expect(Admin.privileges).to include('foo')
    end
  end
end
