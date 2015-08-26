require_relative '../rails_helper'

describe ImportParser do
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

    it 'creates import rows' do
      import = subject.import
      expect(import.rows.count).to eq(1)
      row = import.rows.first
      expect(row.attributes).to include(
        'site_id'  => 1,
        'sequence' => 1
      )
    end

    it 'creates import attributes' do
      import = subject.import
      row = import.rows.first
      attributes = row.import_attributes.map(&:attributes)
      expect(attributes).to match_array([
        include(
          'site_id'   => 1,
          'import_id' => import.id,
          'name'      => 'first_name',
          'value'     => 'Tim',
          'sequence'  => 1
        ),
        include(
          'site_id'   => 1,
          'import_id' => import.id,
          'name'      => 'last_name',
          'value'     => 'Morgan',
          'sequence'  => 2
        ),
        include(
          'site_id'   => 1,
          'import_id' => import.id,
          'name'      => 'email',
          'value'     => 'tim@timmorgan.org',
          'sequence'  => 3
        )
      ])
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
