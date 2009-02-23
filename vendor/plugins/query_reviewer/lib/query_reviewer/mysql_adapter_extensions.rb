module QueryReviewer
  module MysqlAdapterExtensions
    def self.included(base)
      base.alias_method_chain :select, :review if QueryReviewer::CONFIGURATION["enabled"]
      base.alias_method_chain :update, :review if QueryReviewer::CONFIGURATION["enabled"]
      base.alias_method_chain :insert, :review if QueryReviewer::CONFIGURATION["enabled"]
      base.alias_method_chain :delete, :review if QueryReviewer::CONFIGURATION["enabled"]
    end
    
    def update_with_review(sql, *args)
      t1 = Time.now
      result = update_without_review(sql, *args)
      t2 = Time.now

      create_or_add_query_to_query_reviewer!(sql, nil, t2 - t1, nil, "UPDATE", result)

      result
    end

    def insert_with_review(sql, *args)
      t1 = Time.now
      result = insert_without_review(sql, *args)
      t2 = Time.now

      create_or_add_query_to_query_reviewer!(sql, nil, t2 - t1, nil, "INSERT")

      result
    end

    def delete_with_review(sql, *args)
      t1 = Time.now
      result = delete_without_review(sql, *args)
      t2 = Time.now

      create_or_add_query_to_query_reviewer!(sql, nil, t2 - t1, nil, "DELETE", result)

      result
    end
    
    def select_with_review(sql, *args)
      sql.gsub!(/^SELECT /i, "SELECT SQL_NO_CACHE ") if QueryReviewer::CONFIGURATION["disable_sql_cache"]
      @logger.silence { execute("SET PROFILING=1") } if QueryReviewer::CONFIGURATION["profiling"]
      t1 = Time.now
      query_results = select_without_review(sql, *args)
      t2 = Time.now

      if @logger && sql =~ /^select/i && query_reviewer_enabled?
        use_profiling = QueryReviewer::CONFIGURATION["profiling"]
        use_profiling &&= (t2 - t1) >= QueryReviewer::CONFIGURATION["warn_duration_threshold"].to_f / 2.0 if QueryReviewer::CONFIGURATION["production_data"]

        if use_profiling
          t5 = Time.now
          @logger.silence { execute("SET PROFILING=1") }
          t3 = Time.now
          select_without_review(sql, *args)
          t4 = Time.now
          profile = @logger.silence { select_without_review("SHOW PROFILE ALL", *args) }
          @logger.silence { execute("SET PROFILING=0") }
          t6 = Time.now
          Thread.current["queries"].overhead_time += t6 - t5
        else
          profile = nil
        end

        cols = @logger.silence do
          select_without_review("explain #{sql}", *args)
        end

        duration = t3 ? [t2 - t1, t4 - t3].min : t2 - t1
        create_or_add_query_to_query_reviewer!(sql, cols, duration, profile)

        #@logger.debug(format_log_entry("Analyzing #{name}\n", query.to_table)) if @logger.level <= Logger::INFO
      end
      query_results
    end
    
    def query_reviewer_enabled?
      Thread.current["queries"] && Thread.current["queries"].respond_to?(:find_or_create_sql_query) && Thread.current["query_reviewer_enabled"]
    end
    
    def create_or_add_query_to_query_reviewer!(sql, cols, run_time, profile, command = "SELECT", affected_rows = 1)
      if query_reviewer_enabled?
        t1 = Time.now
        Thread.current["queries"].find_or_create_sql_query(sql, cols, run_time, profile, command, affected_rows)
        t2 = Time.now
        Thread.current["queries"].overhead_time += t2 - t1
      end
    end
  end
end