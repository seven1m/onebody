require_relative '../rails_helper'

describe ImportParser do
  let(:person) { FactoryGirl.build(:person) }

  describe '#initialize' do
    subject do
      ImportParser.new(
        person: person,
        filename: 'foo.csv',
        data: 'data',
        strategy_name: 'csv'
      )
    end

    it 'exposes data and other initialized attributes' do
      expect(subject.person).to eq(person)
      expect(subject.filename).to eq('foo.csv')
      expect(subject.data).to eq('data')
    end

    it 'looks up the strategy based on the given strategy name' do
      expect(subject.strategy).to be_a(ImportParser::Strategies::CSV)
    end
  end

  describe '#parse' do
    let(:data) do
      "first_name,last_name,email\n" +
      "Tim,Morgan,tim@timmorgan.org"
    end

    subject do
      ImportParser.new(
        person: person,
        filename: 'foo.csv',
        data: data,
        strategy_name: 'csv'
      )
    end

    before { subject.parse }

    it 'creates a new import' do
      expect(Import.count).to eq(1)
      import = subject.import
      expect(import.attributes).to include(
        'site_id'   => 1,
        'person_id' => person.id,
        'filename'  => 'foo.csv',
        'status'    => 'pending'
      )
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
          'site_id'     => 1,
          'import_id'   => import.id,
          'column_name' => 'first_name',
          'value'       => 'Tim',
          'sequence'    => 1
        ),
        include(
          'site_id'     => 1,
          'import_id'   => import.id,
          'column_name' => 'last_name',
          'value'       => 'Morgan',
          'sequence'    => 2
        ),
        include(
          'site_id'     => 1,
          'import_id'   => import.id,
          'column_name' => 'email',
          'value'       => 'tim@timmorgan.org',
          'sequence'    => 3
        )
      ])
    end
  end
end
