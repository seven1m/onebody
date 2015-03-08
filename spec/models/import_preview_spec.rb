require_relative '../rails_helper'

describe ImportPreview do
  let!(:import) do
    FactoryGirl.create(
      :import,
      status: 'matched',
      match_strategy: 'by_contact_info',
      mappings: {
        'first' => 'first_name',
        'last'  => 'last_name',
        'email' => 'email'
      }
    )
  end

  let!(:row_to_create) do
    FactoryGirl.create(
      :import_row,
      import: import,
      import_attributes_attributes: [
        { import: import, name: 'first', value: 'John', sequence: 1 },
        { import: import, name: 'last', value: 'Smith', sequence: 2 }
      ]
    )
  end

  let!(:row_to_update) do
    FactoryGirl.create(
      :import_row,
      import: import,
      import_attributes_attributes: [
        { import: import, name: 'first', value: 'Johnny', sequence: 1 },
        { import: import, name: 'last', value: 'Smith', sequence: 2 },
        { import: import, name: 'email', value: 'john@example.com', sequence: 3 }
      ]
    )
  end

  let!(:row_to_skip) do
    FactoryGirl.create(
      :import_row,
      import: import,
      import_attributes_attributes: [
        { import: import, name: 'first', value: 'John', sequence: 1 },
        { import: import, name: 'last', value: 'Smith', sequence: 2 },
        { import: import, name: 'email', value: 'john@example.com', sequence: 3 }
      ]
    )
  end

  let!(:person_to_update) do
    FactoryGirl.create(
      :person,
      first_name: 'John',
      last_name: 'Smith',
      email: 'john@example.com'
    )
  end

  subject { ImportPreview.new(import) }

  describe '#preview' do
    it 'updates the status of each row' do
      subject.preview
      expect(row_to_create.reload.status).to eq('created')
      expect(row_to_update.reload.status).to eq('updated')
      expect(row_to_skip.reload.status).to eq('unchanged')
    end

    it 'updates the import status' do
      expect(import.status).to eq('matched')
      subject.preview
      expect(import.status).to eq('previewed')
    end
  end
end
