require_relative '../rails_helper'

describe ImportParser, type: :model do
  let(:person) { FactoryGirl.build(:person) }

  let(:import) do
    Import.create!(
      person:          person,
      filename:        'foo.csv',
      importable_type: 'Person',
      status:          'pending'
    )
  end

  describe '#initialize' do
    subject do
      ImportParser.new(
        import:        import,
        data:          'data',
        strategy_name: 'csv'
      )
    end

    it 'exposes initialized attributes' do
      expect(subject.import).to eq(import)
      expect(subject.data).to eq('data')
    end

    it 'looks up the strategy based on the given strategy name' do
      expect(subject.strategy).to be_a(ImportParser::Strategies::CSV)
    end
  end

  describe '#parse' do
    let(:data) do
      "first_name,last_name,email\n" \
      'Tim,Morgan,tim@timmorgan.org'
    end

    subject do
      ImportParser.new(
        import:        import,
        data:          data,
        strategy_name: 'csv'
      )
    end

    before { subject.parse }

    it 'changes the status to parsed' do
      expect(import.reload.status).to eq('parsed')
    end

    it 'updates the row_count' do
      expect(import.reload.row_count).to eq(1)
    end

    it 'stores the column headings' do
      expect(import.reload.mappings).to eq(
        'first_name' => nil,
        'last_name'  => nil,
        'email'      => nil
      )
    end

    it 'creates import rows' do
      import = subject.import
      expect(import.rows.count).to eq(1)
      row = import.rows.first
      expect(row.attributes).to include(
        'site_id'  => 1,
        'sequence' => 1,
        'status'   => 'parsed',
        'import_attributes' => {
          'first_name' => 'Tim',
          'last_name'  => 'Morgan',
          'email'      => 'tim@timmorgan.org'
        }
      )
    end

    context 'given malformed CSV' do
      let(:data) do
        "first_name,last_name,email\n" \
        'Tim,Morgan,"tim@timmorgan.org'
      end

      it 'changes the status to errored and saves the error message' do
        expect(import.reload.status).to eq('errored')
        expect(import.error_message).to eq('Unclosed quoted field on line 2.')
      end
    end
  end
end
