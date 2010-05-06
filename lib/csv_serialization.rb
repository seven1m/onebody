require 'csv'
module ActiveRecord

  module Serialization
    def to_csv_mine(options = {}, &block)
      CsvSerializer.new(self, options).to_s
    end
  end

  class CsvSerializer < ActiveRecord::Serialization::Serializer

    def serialize
      values = serializable_attribute_names.map do |a|
        options[:read_attribute] ? @record.read_attribute(a).to_s : @record.send(a).to_s
      end
      values += serializable_method_names.map do |a|
        @record.send(a).to_s
      end
      add_includes do |association, records, opts|
        # only handles belongs_to
        if records.is_a?(ActiveRecord::Base)
          values += records.class.column_names.map { |c| records.attributes[c] }
        end
      end
      CSV.generate_line(values)
    end

  end
end

module ActiveSupport
  module CoreExtensions
    module Array
      module Conversions

        def to_csv_mine(options = {})
          raise "Not all elements respond to to_csv_mine" unless all? { |e| e.respond_to? :to_csv_mine }
          serializer = ActiveRecord::CsvSerializer.new(first, options)
          names = serializer.serializable_attribute_names + serializer.serializable_method_names
          options[:include].to_a.each do |association|
            names += Kernel.const_get(association.to_s.classify).column_names.map { |c| "#{association}_#{c}" }
          end
          CSV.generate_line(names) + "\n" +
          map { |e| e.to_csv_mine(options) }.join("\n")
        end

      end
    end
  end
end
