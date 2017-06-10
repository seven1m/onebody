class ImportParser
  attr_reader :import, :data, :strategy, :import

  STRATEGIES = {
    'csv' => Strategies::CSV
  }.freeze

  def initialize(import:, data:, strategy_name:)
    @import = import
    @data = data
    lookup_strategy(strategy_name)
  end

  def lookup_strategy(strategy_name)
    strategy_class = STRATEGIES[strategy_name]
    unless strategy_class
      raise UnknownStrategyError,
            "strategy #{strategy_name} is not known to the importer"
    end
    @strategy = strategy_class.new
  end

  def parse
    parsed = @strategy.parse(@data)
    if parsed[:error]
      @import.status = :errored
      @import.error_message = parsed[:error]
    else
      @import.status = :parsing
      @import.row_count = parsed[:rows].size
      @import.save!
      parsed[:rows].each_with_index do |row, index|
        attributes = attrs_for_row(row)
        next if attributes.empty?
        @import.reload if index % 1000 == 0 # make sure import didn't get deleted
        @import.rows.create!(
          sequence: index + 1,
          import_attributes_attributes: attributes,
          status: :parsed
        )
      end
      @import.mappings = build_mappings(parsed[:headers])
      @import.status = :parsed
    end
    @import.save!
  end

  private

  def build_mappings(headers)
    previous_mappings = @import.mappings || {}
    headers.each_with_object({}) do |name, hash|
      hash[name] = previous_mappings[name]
    end
  end

  def attrs_for_row(row)
    row.each_with_index.map do |(key, value), index|
      value.encode!('UTF-8', invalid: :replace, undef: :replace, replace: ' ') if value.is_a?(String)
      {
        name:      key,
        value:     value,
        import_id: @import.id,
        sequence:  index + 1
      }
    end
  end
end
