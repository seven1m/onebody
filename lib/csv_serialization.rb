require 'csv'
module ActiveRecord
  module Serialization
    def to_csv(options = {}, &block)
      CsvSerializer.new(self, options).to_s
    end
  end
  class CsvSerializer < ActiveRecord::Serialization::Serializer
    def serialize
      CSV.generate_line(serializable_attribute_names.map { |a| @record.send(a).to_s })
    end
  end
end

module ActiveSupport
  module CoreExtensions
    module Array
      module Conversions
        def to_csv(options = {})
          raise "Not all elements respond to to_csv" unless all? { |e| e.respond_to? :to_csv }
          CSV.generate_line(ActiveRecord::CsvSerializer.new(first, options).serializable_attribute_names) + "\n" +
          map { |e| e.to_csv(options) }.join("\n")
        end
      end
    end
  end
end
