class ImportParser
  attr_reader :person, :filename, :data, :strategy, :import

  STRATEGIES = {
    'csv' => Strategies::CSV
  }

  def initialize(person:, filename:, data:, strategy_name:)
    @person = person
    @filename = filename
    @data = data
    lookup_strategy(strategy_name)
  end

  def lookup_strategy(strategy_name)
    strategy_class = STRATEGIES[strategy_name]
    unless strategy_class
      fail UnknownStrategyError,
           "strategy #{strategy_name} is not known to the importer"
    end
    @strategy = strategy_class.new
  end

  def parse
    @import = Import.create!(
      person:   @person,
      filename: @filename,
      status:   'pending'
    )
    @strategy.parse(@data).each_with_index do |row, index|
      @import.rows.create(
        sequence: index + 1,
        import_attributes_attributes: attrs_for_row(row)
      )
    end
  end

  private

  def attrs_for_row(row)
    row.each_with_index.map do |(key, value), index|
      {
        column_name: key,
        value:       value,
        import_id:   @import.id,
        sequence:    index + 1
      }
    end
  end
end
