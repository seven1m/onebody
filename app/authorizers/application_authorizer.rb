class ApplicationAuthorizer < Authority::Authorizer
  def self.default(_adjective, _user)
    false
  end
end
