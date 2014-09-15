class Email

  include HTTParty

  def self.show_routes(skip: 0, limit: 1)
    self.get("/routes", params: {skip: skip, limit: limit})
  end

  def self.create_catch_all
    routes = self.show_routes(limit: 100)
    match = []
    routes["items"].each do |item|
      if item["description"] == "Catch All Route - Created By OneBody" and item["expression"] == "match_recipient('.*@#{Site.current.email_host}')"
        match << item
      end
    end
    if match.empty?
      key = Setting.get(:email, :mailgunapikey)
      self.post("https://api:#{key}@api.mailgun.net/v2/routes", body: self.build_data)
    else
      {"message"=>"Route found."}
    end
  end

  private

  def self.build_data
    data = {}
    data[:priority] = 0
    data[:description] = "Catch All Route - Created By OneBody"
    data[:expression] = "match_recipient('.*@#{Site.current.email_host}')"
    data[:action] = ["forward('http://#{Site.current.host}/emails.mime')", "stop()"]
    return data
  end

end
