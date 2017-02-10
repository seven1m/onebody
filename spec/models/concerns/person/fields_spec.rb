require 'rails_helper'

describe Concerns::Person::Fields do
  let!(:field1)      { FactoryGirl.create(:custom_field) }
  let!(:field2)      { FactoryGirl.create(:custom_field) }
  let!(:field_value) { subject.custom_field_values.create!(field: field1, value: 'foo') }

  subject { FactoryGirl.create(:person) }

  describe '#fields' do
    it 'returns a hash of field ids and values' do
      expect(subject.fields).to eq(field1.id => 'foo')
    end
  end

  describe '#fields=' do
    before do
      subject.fields = { field1.id => 'bar', field2.id.to_s => 'baz' }
      subject.save!
    end

    it 'updates existing custom field values' do
      expect(field_value.reload.value).to eq('bar')
    end

    it 'creates new custom field values' do
      field_value = CustomFieldValue.where(field_id: field2.id).first
      expect(field_value).to be
      expect(field_value.value).to eq('baz')
    end
  end

  describe '#field_changes and #fields_changed?' do
    before do
      subject.reload
    end

    context 'when no changes are made' do
      specify '#field_changes returns an empty hash' do
        expect(subject.field_changes).to eq({})
      end

      specify '#fields_changed? returns false' do
        expect(subject.fields_changed?).to eq(false)
      end
    end

    context 'when changes are made' do
      before do
        subject.fields = { field1.id => 'bar', field2.id.to_s => 'baz' }
      end

      specify '#field_changes returns a hash of changes' do
        expect(subject.field_changes).to eq(
          field1.id => ['foo', 'bar'],
          field2.id => [nil, 'baz']
        )
      end

      specify '#fields_changed? returns true' do
        expect(subject.fields_changed?).to eq(true)
      end
    end
  end
end
