module QueryReviewer
  # a single part of an SQL SELECT query
  class SqlSubQuery < OpenStruct
    include MysqlAnalyzer

    delegate :sql, :to => :parent
    attr_reader :cols, :warnings, :parent
    def initialize(parent, cols)
      @parent = parent
      @warnings = []
      @cols = cols.inject({}) {|memo, obj| memo[obj[0].to_s.downcase] = obj[1].to_s.downcase; memo }
      @cols["query_type"] = @cols.delete("type")
      super(@cols)
    end

    def analyze!
      @warnings = []
      adapter_name = ActiveRecord::Base.connection.instance_variable_get("@config")[:adapter]
      method_name = "do_#{adapter_name}_analysis!"
      self.send(method_name.to_sym)
    end

    def table
      @table[:table]
    end

    private

    def warn(options)
      if (options[:field])
        field = options.delete(:field)
        val = self.send(field)
        options[:problem] = ("#{field.to_s.titleize}: #{val.blank? ? "(blank)" : val}")
      end
      options[:query] = self
      options[:table] = self.table
      @warnings << QueryWarning.new(options)
    end

    def praise(options)
      # no credit, only pain
    end
  end
end