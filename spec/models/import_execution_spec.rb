require_relative '../rails_helper'

describe ImportExecution do
  let!(:import) do
    FactoryGirl.create(
      :import,
      status: 'previewed',
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
        { import: import, name: 'first', value: 'Bob', sequence: 1 },
        { import: import, name: 'last', value: 'Smith', sequence: 2 },
        { import: import, name: 'email', value: 'bob@example.com', sequence: 3 }
      ]
    )
  end

  let!(:row_to_error) do
    FactoryGirl.create(
      :import_row,
      import: import,
      import_attributes_attributes: [
        { import: import, name: 'first', value: '', sequence: 1 },
        { import: import, name: 'last', value: 'Smith', sequence: 2 },
        { import: import, name: 'email', value: 'bob@example.com', sequence: 3 }
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

  let!(:person_to_skip) do
    FactoryGirl.create(
      :person,
      first_name: 'Bob',
      last_name: 'Smith',
      email: 'bob@example.com'
    )
  end

  before { Timecop.freeze }
  after { Timecop.return }

  subject { ImportExecution.new(import) }

  describe '#execute' do
    it 'updates the status of each row' do
      subject.execute
      expect(row_to_create.reload.status).to eq('created')
      expect(row_to_update.reload.status).to eq('updated')
      expect(row_to_skip.reload.status).to eq('unchanged')
      expect(row_to_error.reload.status).to eq('errored')
    end

    it 'records errors' do
      subject.execute
      expect(row_to_error.reload.error_reasons).to eq('The person must have a first name.')
    end

    it 'updates the import status' do
      expect(import.status).to eq('previewed')
      subject.execute
      expect(import.status).to eq('complete')
    end

    it 'updates the completed_at time' do
      subject.execute
      expect(import.completed_at).to eq(Time.now)
    end
  end
end
