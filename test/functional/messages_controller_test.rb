require 'test_helper'

class MessagesControllerTest < ActionController::TestCase

  def setup
    @person = Person.create! :first_name => Faker::Name.first_name, :last_name => Faker::Name.last_name, :gender => 'Male'
  end
  
  should "allow the creation of new wall posts via regular post" #do
    #body = Faker::Lorem.sentence
    #post :create, {:id => @person.id, 'message[body]' => body}, {:logged_in_id => people(:jeremy).id}
    #assert_redirected_to 
  #end   
   
  should "allow the creation of new wall posts via ajax" #do
    #body = Faker::Lorem.sentence
    #post :create, {:id => @person.id, 'message[body]' => body}, {:logged_in_id => people(:jeremy).id}
    #assert_redirected_to 
  #end

  should "not allow the creation of a new wall post if the user cannot see the person's profile"
  
  should "allow a wall post to be deleted"

  should "not allow anyone but an admin or the owner to delete a wall post"

end
