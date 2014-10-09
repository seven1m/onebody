class Email

  include HTTParty

  def self.show_routes(skip: 0, limit: 1)
    key = Setting.get(:email, :mailgunapikey)
    get('https://api.mailgun.net/v2/routes',
        basic_auth: { username: 'api', password: key },
        params: { skip: skip, limit: limit })
  end

  def self.create_catch_all
    routes = show_routes(limit: 100)
  rescue Exception => e
    { 'message' => 'error' }
    Rails.logger.error(e.message)
  else
    if routes.to_s == 'Forbidden'
      { 'message' => 'apikey' }
    else
      match = []
      routes['items'].each do |item|
        if item['description'] == 'Catch All Route - Created By OneBody' and
          item['expression'] == "match_recipient('.*@#{Site.current.email_host}')"
          match << item
        end
      end
      if match.empty?
        key = Setting.get(:email, :mailgunapikey)
        post('https://api.mailgun.net/v2/routes',
             basic_auth: { username: 'api', password: key },
             body: build_data)
      else
        { 'message' => 'Route found.' }
      end
    end
  end

  private

  def self.build_data
    data = {}
    data[:priority] = 0
    data[:description] = 'Catch All Route - Created By OneBody'
    data[:expression] = "match_recipient('.*@#{Site.current.email_host}')"
    data[:action] = ["forward('http://#{Site.current.host}/emails.mime')", "stop()"]
    return data
  end

end
