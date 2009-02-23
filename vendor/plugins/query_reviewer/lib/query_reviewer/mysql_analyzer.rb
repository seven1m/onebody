module QueryReviewer
  module MysqlAnalyzer
    def do_mysql_analysis!
      analyze_select_type!
      analyze_query_type!
      analyze_key!
      analyze_extras!
      analyze_keylen!
    end

    def analyze_select_type!
      if select_type.match /uncacheable subquery/
        warn(:severity => 10, :field => "select_type", :desc => "Subquery must be run once for EVERY row in main query")
      elsif select_type.match /dependent/
        warn(:severity => 2, :field => "select_type", :desc => "Dependent subqueries can not be executed while the main query is running")
      end
    end

    def analyze_query_type!
      case query_type
      when "system", "const", "eq_ref":
        praise("Yay")
      when "ref", "ref_or_null", "range", "index_merge":
        praise("Not bad eh...")
      when "unique_subquery", "index_subquery":
        #NOT SURE
      when "index":
        warn(:severity => 8, :field => "query_type", :desc => "Full index tree scan (slightly faster than a full table scan)") unless !extra.include?("using where")
      when "all":
        warn(:severity => 9, :field => "query_type", :desc => "Full table scan") unless !extra.include?("using where")
      end
    end

    def analyze_key!
      if self.key == "const"
        praise "Way to go!"
      elsif self.key.blank? && !self.extra.include?("select tables optimized away")
        warn :severity => 6, :field => "key", :desc => "No index was used here. In this case, that meant scanning #{self.rows} rows."
      end
    end

    def analyze_extras!
      if self.extra.match(/range checked for each record/)
        warn :severity => 4, :problem => "Range checked for each record", :desc => "MySQL found no good index to use, but found that some of indexes might be used after column values from preceding tables are known"
      end

      if self.extra.match(/using filesort/)
        warn :severity => 2, :problem => "Using filesort", :desc => "MySQL must do an extra pass to find out how to retrieve the rows in sorted order."
      end

      if self.extra.match(/using temporary/)
        warn :severity => 10, :problem => "Using temporary table", :desc => "To resolve the query, MySQL needs to create a temporary table to hold the result."
      end
    end

    def analyze_keylen!
      if self.key_len && !self.key_len.to_i.nil? && (self.key_len.to_i > QueryReviewer::CONFIGURATION["max_safe_key_length"])
        warn :severity => 4, :problem => "Long key length (#{self.key_len.to_i})", :desc => "The key used for the index was rather long, potentially affecting indices in memory"
      end
    end
  end
end
