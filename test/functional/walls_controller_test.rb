require 'test_helper'

class WallsControllerTest < ActionController::TestCase
  
  def setup
    @family1 = Family.create! :name => Faker::Name.name, :last_name => Faker::Name.last_name
    @person = @family1.people.create! :first_name => Faker::Name.first_name, :last_name => Faker::Name.last_name, :gender => 'Male', :visible_to_everyone => true, :visible => true, :can_sign_in => true, :full_access => true, :email => Faker::Internet.email, :encrypted_password => '5ebe2294ecd0e0f08eab7690d2a6ee69'
    @family2 = Family.create! :name => Faker::Name.name, :last_name => Faker::Name.last_name
    @other_person = @family2.people.create! :first_name => Faker::Name.first_name, :last_name => Faker::Name.last_name, :gender => 'Male', :visible_to_everyone => true, :visible => true, :can_sign_in => true, :full_access => true, :email => Faker::Internet.email, :encrypted_password => '5ebe2294ecd0e0f08eab7690d2a6ee69'
    15.times do
      @person.wall_messages.create! :subject => 'Wall Post', :body => Faker::Lorem.sentence, :person => @other_person
    end
    12.times do
      @other_person.wall_messages.create! :subject => 'Wall Post', :body => Faker::Lorem.sentence, :person => @person
    end
  end
    
  should "show all messages from one person's wall when rendered as html" do
    get :show, {:id => @person.id}, {:logged_in_id => @other_person.id}
    assert_response :success
    assert_template 'show'
    assert assigns(:person)
    assert assigns(:messages)
    assert_equal @person.wall_messages.count, assigns(:messages).length
  end

  should "show 10 messages from one person's wall when rendered for ajax" do
    get :show, {:id => @person.id, :format => 'js'}, {:logged_in_id => @other_person.id}
    assert_response :success
    assert_template '_wall'
    assert assigns(:person)
    assert assigns(:messages)
    assert_equal 10, assigns(:messages).length
  end

  should "not show a peron's wall if the user cannot see the profile" do
    @person.update_attribute :visible_to_everyone, false
    get :show, {:id => @person.id}, {:logged_in_id => @other_person.id}
    assert_response :missing
  end
  
  should "not show a person's wall if they have it disabled" do
    @person.update_attribute :wall_enabled, false
    get :show, {:id => @person.id}, {:logged_in_id => @other_person.id}
    assert_response :missing
  end
  
  should "show the interaction of two people (wall-to-wall)" do
    get :index, {'id' => [@person.id, @other_person.id]}, {:logged_in_id => @other_person.id}
    assert_response :success
    assert_template 'index'
    assert assigns(:person1)
    assert assigns(:person2)
    assert assigns(:messages)
    assert_equal (@person.wall_messages.count + @other_person.wall_messages.count), assigns(:messages).length
  end

  should "not show the interaction of two people (wall-to-wall) if any one of the people cannot be seen by the current user" do
    @person.update_attribute :visible_to_everyone, false
    get :index, {'id' => [@person.id, @other_person.id]}, {:logged_in_id => @other_person.id}
    assert_response :missing
  end
  
  should "not show the interaction of two people (wall-to-wall) if any of the people have their wall disabled" do
    @person.update_attribute :wall_enabled, false
    get :index, {'id' => [@person.id, @other_person.id]}, {:logged_in_id => @other_person.id}
    assert_response :missing
  end
  
  should "not show index unless at least two people's ids are specified" do
    get :index, nil, {:logged_in_id => @other_person.id}
    assert_response :error
    get :index, {'id' => [@person.id]}, {:logged_in_id => @other_person.id}
    assert_response :error
  end

end
