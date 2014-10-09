module CountrySelectHelper
  class CountrySelectWrapper
    include CountrySelect::TagHelper

    def initialize
      @options = {}
    end

    def options
      country_options
    end
  end

  def country_options
    CountrySelectWrapper.new.options
  end
end
