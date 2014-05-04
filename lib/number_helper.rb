module ActionView
  module Helpers
    module NumberHelper
      def number_to_phone(number, options = {})
        number       = number.to_s.strip unless number.nil?
        options      = options.stringify_keys
        area_code    = options["area_code"] || nil
        delimiter    = options["delimiter"] || "-"
        extension    = options["extension"].to_s.strip || nil
        country_code = options["country_code"] || nil
        g1, g2, g3   = options["groupings"] || [3, 3, 4]

        re = Regexp.new("([0-9]{1,#{g1}})([0-9]{#{g2}})([0-9]{#{g3}})$")

        begin
          str = ""
          str << "+#{country_code}#{delimiter}" unless country_code.blank?
          str << if area_code
            number.gsub!(re, "(\\1) \\2#{delimiter}\\3")
          else
            number.gsub!(re, "\\1#{delimiter}\\2#{delimiter}\\3")
          end
          str << " x #{extension}" unless extension.blank?
          str
        rescue
          number
        end
      end
    end
  end
end
