require 'rspec/expectations'

RSpec::Matchers.define :be_unauthorized do
  match do |response|
    response.status == 401
  end
end
