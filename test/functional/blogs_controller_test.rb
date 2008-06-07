require 'test_helper'

class BlogsControllerTest < ActionController::TestCase
  
  def setup
    @person = FixtureFactory::Person.create
    @other_person = FixtureFactory::Person.create
    Person.logged_in = @person
    5.times do
      verse = Verse.new(:text => Faker::Lorem.sentence)
      verse.write_attribute :reference, "#{Faker::Lorem.words(1).join} #{rand(25)}:#{rand(50)}"
      @person.verses << verse
    end
    5.times  { @person.recipes.create! :title => Faker::Lorem.words(1).join, :ingredients => Faker::Lorem.paragraph, :directions => Faker::Lorem.paragraph }
    8.times  { @person.notes.create! :title => Faker::Lorem.words(1).join, :body => Faker::Lorem.paragraph }
    10.times { @person.pictures.create!.photo = File.open(File.dirname(__FILE__) + '/../../public/images/man.gif') }
  end
  
  should "show 25 blog items separated by pictures and non-pictures" do
    get :show, {:id => @person.id}, {:logged_in_id => @other_person.id}
    assert_equal 25, assigns(:pictures).length + assigns(:non_pictures).length
  end
  
  should "not show the blog if the logged in user cannot see the person" do
    @person.update_attribute :visible, false
    get :show, {:id => @person.id}, {:logged_in_id => @other_person.id}
    assert_response :missing
  end
  
  should "not show any deleted blog items" do
    @person.notes.destroy_all
    get :show, {:id => @person.id}, {:logged_in_id => @other_person.id}
    assert_equal 0, assigns(:non_pictures).select { |o| o.is_a? Note }.length
  end
  
  # future...
  #should "not show any blog items if the person has their blog disabled"
  
end
