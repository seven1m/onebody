class ApplicationReport
  def initialize(options)
    @options = options.with_indifferent_access
  end

  attr_reader :options

  def formatted_title
    self.class.name.titleize
  end

  def results
    execute
  end

  def to_param
    self.class.name.underscore.sub(/_report$/, '')
  end

  def execute
    ActiveRecord::Base.connection.select_all(sql).to_a.map(&:values)
  end

  def headings
    raise 'must override in report class'
  end

  def sql
    raise 'must override in report class'
  end

  def to_csv
    CSV.generate do |csv|
      csv << headings if headings
      results.each do |result|
        csv << result.map do |value|
          if value.respond_to?(:strftime)
            value.to_s(:full)
          else
            value
          end
        end
      end
    end
  end
end
