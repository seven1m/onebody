module Requests
  module JsonHelpers
    def json
      @json ||= JSON.parse(response.body)
    end

    def json_data
      json['data']
    end

    def json_attributes
      json_data['attributes']
    end
  end
end