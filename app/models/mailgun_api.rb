class MailgunApi
  include HTTParty

  class RouteAlreadyExists < StandardError; end
  class Forbidden < StandardError; end
  class KeyMissing < StandardError; end

  def initialize(key)
    @key = key
    fail KeyMissing if @key.blank?
  end

  def show_routes(skip: 0, limit: 100)
    get(
      'https://api.mailgun.net/v2/routes',
      params: { skip: skip, limit: limit }
    )
  end

  def domains(skip: 0, limit: 100)
    get(
      'https://api.mailgun.net/v2/domains',
      params: { skip: skip, limit: limit }
    )['items']
  end

  def create_catch_all
    routes = show_routes
    if routes.to_s == 'Forbidden'
      { 'message' => 'apikey' }
    else
      if matching_routes(routes).any?
        fail RouteAlreadyExists
      else
        post(
          'https://api.mailgun.net/v2/routes',
          body: build_data
        )
        true
      end
    end
  end

  private

  def get(url, options)
    options = options.merge(
      basic_auth: { username: 'api', password: @key },
    )
    response = self.class.get(url, options)
    fail Forbidden if response.code == 401
    response
  end

  def post(url, options)
    options = options.merge(
      basic_auth: { username: 'api', password: @key },
    )
    response = self.class.post(url, options)
    fail Forbidden if response.code == 401
    response
  end

  def matching_routes(routes)
    match = []
    routes['items'].each do |item|
      next if item['description'] != 'Catch All Route - Created By OneBody'
      next if item['expression'] != "match_recipient('.*@#{Site.current.email_host}')"
      match << item
    end
  end

  def build_data
    {
      priority: 0,
      description: 'Catch All Route - Created By OneBody',
      expression: "match_recipient('.*@#{Site.current.email_host}')",
      action: ["forward('http://#{Site.current.host}/emails.mime')", 'stop()']
    }
  end
end
