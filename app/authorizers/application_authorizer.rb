class ApplicationAuthorizer < Authority::Authorizer

  def self.default(adjective, user)
    false
  end

end
