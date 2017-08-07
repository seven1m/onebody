require 'rails_helper'

describe CustomField do
  describe '#format' do
    it { should allow_value('string').for(:format) }
    it { should allow_value('number').for(:format) }
    it { should allow_value('boolean').for(:format) }
    it { should allow_value('date').for(:format) }
    it { should allow_value('select').for(:format) }
    it { should_not allow_value('xyz').for(:format) }
    it { should_not allow_value('').for(:format) }
    it { should_not allow_value(nil).for(:format) }
  end
end
