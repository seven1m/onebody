class MailgunApi
  include HTTParty

  class Forbidden < StandardError; end
  class KeyMissing < StandardError; end

  def initialize(key:, scheme:)
    @key = key
    @scheme = scheme
    raise KeyMissing if @key.blank?
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

  def create_catch_all(domain)
    routes = show_routes
    if routes.to_s == 'Forbidden'
      raise Forbidden
    else
      onebody_routes(routes).each do |route_to_delete|
        delete("https://api.mailgun.net/v2/routes/#{route_to_delete['id']}")
      end
      post(
        'https://api.mailgun.net/v2/routes',
        body: build_data(domain)
      )
      true
    end
  end

  private

  def get(url, options)
    options = options.merge(
      basic_auth: { username: 'api', password: @key }
    )
    response = self.class.get(url, options)
    raise Forbidden if response.code == 401
    response
  end

  def post(url, options)
    options = options.merge(
      basic_auth: { username: 'api', password: @key }
    )
    response = self.class.post(url, options)
    raise Forbidden if response.code == 401
    response
  end

  def delete(url, options = {})
    options = options.merge(
      basic_auth: { username: 'api', password: @key }
    )
    response = self.class.delete(url, options)
    raise Forbidden if response.code == 401
    response
  end

  def onebody_routes(routes)
    routes['items'].select do |item|
      ['Route all email to OneBody', 'Catch All Route - Created By OneBody'].include?(item['description'])
    end
  end

  def build_data(domain)
    {
      priority: 0,
      description: 'Route all email to OneBody',
      expression: "match_recipient('.*@#{domain}')",
      action: ["forward(\"#{@scheme}://#{Site.current.host}/emails.mime\")", 'stop()']
    }
  end
end
