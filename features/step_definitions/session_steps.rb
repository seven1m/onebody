Given /^I am signed in as a user$/ do
  @person = Person.forge
  post '/session', :email => @person.email, :password => @person.password
  response.should be_redirect
end
