require_relative '../rails_helper'

describe ImportAttribute do
  describe 'validations' do
    it { should validate_presence_of(:import) }
    it { should validate_presence_of(:row) }
  end
end
