module Liquid
  
  module StandardFilters
    
    # Return the size of an array or of an string
    def size(input)
      
      input.respond_to?(:size) ? input.size : 0
    end         
    
    # convert a input string to DOWNCASE
    def downcase(input)
      input.downcase rescue input
    end         

    # convert a input string to UPCASE
    def upcase(input)
      input.upcase rescue input
    end
    
    # Truncate a string down to x characters
    def truncate(input, characters = 100)    
      if input.to_s.size > characters.to_i
        input.to_s[0..characters.to_i] + '&hellip;'
      else
        input
      end
    end  

    # Truncate string down to x words
    def truncatewords(input, words = 15)    
      wordlist = [input.to_s.split].flatten
      if wordlist.size > words.to_i
        wordlist[0..words.to_i].join(' ') + '&hellip;'
      else
        input
      end
    end  
    
    def strip_html(input)
      input.to_s.gsub(/<.*?>/, '')
    end
    
    # Join elements of the array with certain character between them
    def join(input, glue = ' ')
      [input].flatten.join(glue)
    end

    # Sort elements of the array
    def sort(input)
      [input].flatten.sort
    end
    
    # Reformat a date
    #
    #   %a - The abbreviated weekday name (``Sun'')
    #   %A - The  full  weekday  name (``Sunday'')
    #   %b - The abbreviated month name (``Jan'')
    #   %B - The  full  month  name (``January'')
    #   %c - The preferred local date and time representation
    #   %d - Day of the month (01..31)
    #   %H - Hour of the day, 24-hour clock (00..23)
    #   %I - Hour of the day, 12-hour clock (01..12)
    #   %j - Day of the year (001..366)
    #   %m - Month of the year (01..12)
    #   %M - Minute of the hour (00..59)
    #   %p - Meridian indicator (``AM''  or  ``PM'')
    #   %S - Second of the minute (00..60)
    #   %U - Week  number  of the current year,
    #           starting with the first Sunday as the first
    #           day of the first week (00..53)
    #   %W - Week  number  of the current year,
    #           starting with the first Monday as the first
    #           day of the first week (00..53)
    #   %w - Day of the week (Sunday is 0, 0..6)
    #   %x - Preferred representation for the date alone, no time
    #   %X - Preferred representation for the time alone, no date
    #   %y - Year without a century (00..99)
    #   %Y - Year with century
    #   %Z - Time zone name
    #   %% - Literal ``%'' character
    def date(input, format)
      date = input
      date = Time.parse(input) if input.is_a?(String)
      date.strftime(format)      
    rescue => e 
      input
    end
    
    # Get the first element of the passed in array 
    # 
    # Example:
    #    {{ product.images | first | to_img }}
    #  
    def first(array)
      array.first if array.respond_to?(:first)
    end

    # Get the last element of the passed in array 
    # 
    # Example:
    #    {{ product.images | last | to_img }}
    #  
    def last(array)
      array.last if array.respond_to?(:last)
    end
    
  end
   
  Template.register_filter(StandardFilters)
end
