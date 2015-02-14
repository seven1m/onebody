require_relative '../rails_helper'

describe ImportRow do
  describe 'validations' do
    it { should validate_presence_of(:import) }
    it { should validate_presence_of(:status) }
    it { should validate_presence_of(:sequence) }
  end
end
