module PluginAWeek #:nodoc:
  module CoreExtensions #:nodoc:
    module Date #:nodoc:
      module DayQuestions
        # Is it yesterday?
        def yesterday?
          self == 1.day.ago.to_date
        end
        
        # Is it today?
        def today?
          self == self.class.today
        end
        
        # Is it tomorrow?
        def tomorrow?
          self == 1.day.from_now.to_date
        end
        
        # Is it in the last few days?
        def recent?
          self >= 3.day.ago.to_date
        end
        
        # Is it yesterday, today, or tomorrow?
        def around_today?
          yesterday? || today? || tomorrow?
        end
        
        # The human day defines a value based on whether the Date is around the
        # current day.  If the Date is not around today, then the argument
        # passed in will be used.  The default for this value is "on month/day".
        # 
        # For example, if today is 12/31/2006:
        # 
        #   Date.parse('12/31/2006').human_date           # => Today
        #   Date.parse('12/30/2006').human_date           # => Yesterday
        #   Date.parse('1/1/2007').human_date             # => Tomorrow
        #   Date.parse('12/29/2006').human_date           # => on 12/29
        #   Date.parse('12/29/2006').human_date('on %a')  # => on Fri
        def human_day(recent_format="%A", not_recent_format="%B %d")
          if today?
            "Today"
          elsif yesterday?
            "Yesterday"
          elsif tomorrow?
            "Tomorrow"
          elsif recent?
            strftime(recent_format)
          else
            strftime(not_recent_format)
          end
        end
      end
    end
    
    module Time #:nodoc:
      module DayQuestions
        delegate  :yesterday?,
                  :today?,
                  :tomorrow?,
                  :around_today?,
                  :human_day,
                    :to => :to_date
      end
    end
  end
end

class ::Date #:nodoc:
  include PluginAWeek::CoreExtensions::Date::DayQuestions
end

class ::Time #:nodoc:
  include PluginAWeek::CoreExtensions::Time::DayQuestions
end