require "test/unit"
require 'test/unit/ui/console/testrunner'
require 'rubygems'
require 'activeresource'
require File.dirname(__FILE__) + '/test_extensions'

class PersonResource < ActiveResource::Base
  self.site = 'http://localhost:3001/'
  self.element_name = 'person'
end
  
class ApiTest < Test::Unit::TestCase

  def setup
    PersonResource.user = 'admin@example.com'
    PersonResource.password = 'dafH2KIiAcnLEr5JxjmX2oveuczq0R6u7Ijd329DtjatgdYcKp'
  end

  should "not allow access unless user is super admin" do
    PersonResource.user = 'user@example.com'
    assert_raise(ActiveResource::Redirection) do
      PersonResource.find(1)
    end
  end
  
  should "fetch a person" do
    person = PersonResource.find(1)
    assert person
    assert_equal 'Tim', person.first_name
  end
  
  should "update a person" do
    person = PersonResource.find(1)
    person.first_name = 'Joe'
    person.save
    assert_equal 'Joe', PersonResource.find(1).first_name
  end
  
  should "not mangle share_ attributes when updating a person"
  
  should "create a person"
  
  should "delete a person"
end

if $0 == __FILE__
  puts `cd #{File.dirname(__FILE__)}/.. && rake db:schema:load db:fixtures:load RAILS_ENV=test && mongrel_rails start -p 3001 -e test -d`
  sleep 1
  Test::Unit::UI::Console::TestRunner.run(ApiTest)
  puts `cd #{File.dirname(__FILE__)}/.. && mongrel_rails stop`
end
