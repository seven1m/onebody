module ActiveRecord
  module ConnectionAdapters
    class Column
      def self.string_to_time(string)
        return string unless string.is_a?(String)
        date_array = ParseDate.parsedate(string)
        DateTime.new(*date_array.compact) rescue nil
      end
    end
  end
end

class DateTime
  def to_s
    strftime '%Y-%m-%d %H:%M:%S'
  end
end