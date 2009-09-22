class Date
  class << self
    def _parse_with_american_date(str, comp=true)
      _parse_without_american_date(str.sub(/(\d{1,2})\/(\d{1,2})\/(\d{4})/, '\3/\1/\2'), comp)
    end
    alias_method_chain :_parse, :american_date
  end
end
