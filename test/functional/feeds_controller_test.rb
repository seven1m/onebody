require File.dirname(__FILE__) + '/../test_helper'

class FeedsControllerTest < ActionController::TestCase
  
  def setup
    @person, @other_person = Person.forge, Person.forge
    @group = Group.create! :name => Faker::Lorem.words(1).join, :category => Faker::Lorem.words(1).join
    @group.memberships.create! :person => @person
    @group.memberships.create! :person => @other_person
    @person.forge_blog
    3.times  { Person.logged_in = @person;       @person.messages.create!       :group => @group, :subject => Faker::Lorem.sentence, :body => Faker::Lorem.paragraph }
    3.times  { Person.logged_in = @other_person; @other_person.messages.create! :group => @group, :subject => Faker::Lorem.sentence, :body => Faker::Lorem.paragraph }
  end

  should "show 25 actions related to the person" do
    get :show, nil, {:logged_in_id => @person.id}
    assert_equal 25, assigns(:items).length
  end
  
  should "not show the feed of anyone but the logged in user" do
    get :show, {:id => @person.id}, {:logged_in_id => @other_person.id}
    assert_equal @other_person, assigns(:person)
  end
  
  should "show the feed if the user is logged in or the security code is provided" do
    get :show, nil,                          {:logged_in_id => @person.id}; assert_response :success
    get :show, {:code => @person.feed_code}, {:logged_in_id => nil};        assert_response :success
    get :show, {:code => 'bad code'},        {:logged_in_id => nil};        assert_response :redirect
    get :show, nil,                          {:logged_in_id => nil};        assert_response :redirect
  end
  
  should "show the feed as RSS" do
    get :show, {:format => 'xml', :code => @person.feed_code}, {:logged_in_id => nil}
    assert_response :success
    assert_tag :tag => 'feed'
    assert_tag :tag => 'entry'
  end
  
end
