module Client
  require "active_resource"
  
  class Project < ActiveResource::Base
    self.site = "http://localhost:4000/"
  end
end