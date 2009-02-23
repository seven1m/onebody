require "ostruct"

module QueryReviewer
  # a single SQL SELECT query
  class SqlQuery
    attr_reader :sqls, :rows, :subqueries, :trace, :id, :command, :affected_rows, :profiles, :durations, :sanitized_sql

    cattr_accessor :next_id
    self.next_id = 1

    def initialize(sql, rows, full_trace, duration = 0.0, profile = nil, command = "SELECT", affected_rows = 1, sanitized_sql = nil)
      @trace = full_trace
      @rows = rows
      @sqls = [sql]
      @sanitized_sql = sanitized_sql
      @subqueries = rows ? rows.collect{|row| SqlSubQuery.new(self, row)} : []
      @id = (self.class.next_id += 1)
      @profiles = profile ? [profile.collect { |p| OpenStruct.new(p) }] : [nil]
      @durations = [duration.to_f]
      @warnings = []
      @command = command
      @affected_rows = affected_rows
    end
    
    def add(sql, duration, profile)
      sql << sql
      durations << duration
      profiles << profile
    end
    
    def sql
      sqls.first
    end
    
    def count
      durations.size
    end
    
    def profile
      profiles.first
    end
    
    def duration
      durations.sum
    end

    def duration_stats
      "TOTAL:#{'%.3f' % duration}  AVG:#{'%.3f' % (durations.sum / durations.size)}  MAX:#{'%.3f' % (durations.max)}  MIN:#{'%.3f' % (durations.min)}"
    end

    def to_table
      rows.qa_columnized
    end

    def warnings
      self.subqueries.collect(&:warnings).flatten + @warnings
    end

    def has_warnings?
      !self.warnings.empty?
    end

    def max_severity
      self.warnings.empty? ? 0 : self.warnings.collect(&:severity).max
    end

    def table
      @subqueries.first.table
    end

    def analyze!
      self.subqueries.collect(&:analyze!)
      if duration
        if duration >= QueryReviewer::CONFIGURATION["critical_duration_threshold"]
          warn(:problem => "Query took #{duration} seconds", :severity => 9)
        elsif duration >= QueryReviewer::CONFIGURATION["warn_duration_threshold"]
          warn(:problem => "Query took #{duration} seconds", :severity => QueryReviewer::CONFIGURATION["critical_severity"])
        end
      end
      
      if affected_rows >= QueryReviewer::CONFIGURATION["critical_affected_rows"]
        warn(:problem => "#{affected_rows} rows affected", :severity => 9, :description => "An UPDATE or DELETE query can be slow and lock tables if it affects many rows.")
      elsif affected_rows >= QueryReviewer::CONFIGURATION["warn_affected_rows"]
        warn(:problem => "#{affected_rows} rows affected", :severity => QueryReviewer::CONFIGURATION["critical_severity"], :description => "An UPDATE or DELETE query can be slow and lock tables if it affects many rows.")
      end
    end

    def to_hash
      @sql.hash
    end

    def relevant_trace
      trace.collect(&:strip).select{|t| t.starts_with?(RAILS_ROOT) &&
          (!t.starts_with?("#{RAILS_ROOT}/vendor") || QueryReviewer::CONFIGURATION["trace_includes_vendor"]) &&
          (!t.starts_with?("#{RAILS_ROOT}/lib") || QueryReviewer::CONFIGURATION["trace_includes_lib"]) &&
          !t.starts_with?("#{RAILS_ROOT}/vendor/plugins/query_reviewer") }
    end

    def full_trace
      self.class.generate_full_trace(trace)
    end

    def warn(options)
      options[:query] = self
      options[:table] ||= self.table
      @warnings << QueryWarning.new(options)
    end

    def select?
      self.command == "SELECT"
    end
    
    def self.generate_full_trace(trace = Kernel.caller)
      trace.collect(&:strip).select{|t| !t.starts_with?("#{RAILS_ROOT}/vendor/plugins/query_reviewer") }
    end
    
    def self.sanitize_strings_and_numbers_from_sql(sql)
      new_sql = sql.clone
      new_sql.gsub!(/\b\d+\b/, "N")
      new_sql.gsub!(/\b0x[0-9A-Fa-f]+\b/, "N")
      new_sql.gsub!(/''/, "'S'")
      new_sql.gsub!(/""/, "\"S\"")
      new_sql.gsub!(/\\'/, "")
      new_sql.gsub!(/\\"/, "")
      new_sql.gsub!(/'[^']+'/, "'S'")
      new_sql.gsub!(/"[^"]+"/, "\"S\"")
      new_sql
    end
  end
end