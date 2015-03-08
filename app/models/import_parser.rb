class ImportParser
  attr_reader :import, :data, :strategy, :import

  STRATEGIES = {
    'csv' => Strategies::CSV
  }

  def initialize(import:, data:, strategy_name:)
    @import = import
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
    parsed = @strategy.parse(@data)
    @import.update_attribute(:status, 'parsing')
    if parsed[:error]
      @import.status = :errored
      @import.error_message = parsed[:error]
    else
      parsed[:rows].each_with_index do |row, index|
        attributes = attrs_for_row(row)
        next if attributes.empty?
        @import.rows.create!(
          sequence: index + 1,
          status: 'pending',
          import_attributes_attributes: attributes
        )
      end
      @import.mappings = Hash[parsed[:headers].zip]
      @import.status = :parsed
    end
    @import.save!
  end

  private

  def attrs_for_row(row)
    row.each_with_index.map do |(key, value), index|
      {
        name:      key,
        value:     value,
        import_id: @import.id,
        sequence:  index + 1
      }
    end
  end
end
