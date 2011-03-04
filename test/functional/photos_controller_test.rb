require File.dirname(__FILE__) + '/../test_helper'

class PhotosControllerTest < ActionController::TestCase

  def setup
    @family = Family.forge
    @person = Person.forge
  end

  should "update a photo" do
    post :update, {:family_id => @person.family.id, :photo => Rack::Test::UploadedFile.new(Rails.root.join('test/fixtures/files/image.jpg'), 'image/jpeg', true)},
      {:logged_in_id => @person.id}
    assert_response :redirect
  end

  should "not update a photo unless user can edit the object" do
    post :update, {:family_id => @family.id, :photo => Rack::Test::UploadedFile.new(Rails.root.join('test/fixtures/files/image.jpg'), 'image/jpeg', true)},
      {:logged_in_id => @person.id}
    assert_response :error
  end

  should "not update a photo with invalid content type" do
    post :update, {:family_id => @person.family.id, :photo => Rack::Test::UploadedFile.new(Rails.root.join('test/fixtures/files/image.bmp'), 'image/bmp', true)},
      {:logged_in_id => @person.id}
    assert_response :redirect
    assert flash[:warning]
  end

  should "delete a photo" do
    post :destroy, {:family_id => @person.family.id}, {:logged_in_id => @person.id}
    assert_response :redirect
  end

  should "not delete a photo unless user can edit the object" do
    post :destroy, {:family_id => @family.id}, {:logged_in_id => @person.id}
    assert_response :error
  end

end
