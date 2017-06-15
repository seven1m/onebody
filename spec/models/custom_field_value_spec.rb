require 'rails_helper'

describe CustomFieldValue do
  describe 'validations' do
    subject { FactoryGirl.build(:custom_field_value, field: field) }

    context 'string format field' do
      let(:field) { FactoryGirl.create(:custom_field, format: 'string') }

      it { should allow_value('').for(:value) }
      it { should allow_value('foo').for(:value) }
      it { should allow_value(1).for(:value) }
    end

    context 'number format field' do
      let(:field) { FactoryGirl.create(:custom_field, format: 'number') }

      it { should allow_value('').for(:value) }
      it { should allow_value(1).for(:value) }
      it { should_not allow_value('foo').for(:value) }
    end

    context 'boolean format field' do
      let(:field) { FactoryGirl.create(:custom_field, format: 'boolean') }

      it { should allow_value('0').for(:value) }
      it { should allow_value('1').for(:value) }
      it { should allow_value('TRUE').for(:value) }
      it { should allow_value('yes').for(:value) }
    end

    context 'date format field' do
      let(:field) { FactoryGirl.create(:custom_field, format: 'date') }

      it { should allow_value('').for(:value) }
      it { should_not allow_value(1).for(:value) }
      it { should_not allow_value('foo').for(:value) }
      it { should allow_value('2016-01-01').for(:value) }
      it { should allow_value('12/31/2016').for(:value) }
    end
  end
end
