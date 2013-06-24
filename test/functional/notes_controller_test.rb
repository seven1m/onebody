require_relative '../test_helper'

class NotesControllerTest < ActionController::TestCase

  def setup
    @person, @other_person = FactoryGirl.create_list(:person, 2)
    @note = FactoryGirl.create(:note, person: @person)
  end

  #should "list all notes" do
  #  get :index, nil, {:logged_in_id => @person.id}
  #  assert_response :success
  #  assert_equal 1, assigns(:notes).length
  #end

  should "show a note" do
    get :show, {id: @note.id}, {logged_in_id: @person.id}
    assert_response :success
    assert_equal @note, assigns(:note)
  end

  should "not show a note unless user can see note owner" do
    @person.update_attribute :visible, false
    get :show, {id: @note.id}, {logged_in_id: @other_person.id}
    assert_response :unauthorized
  end

  should "create a new personal note" do
    get :new, nil, {logged_in_id: @person.id}
    assert_response :success
    post :create, {
      note: {title: 'test title', body: 'test body'}
    }, {logged_in_id: @person.id}
    @new_note = Note.last
    assert_equal 'test title', @new_note.title
    assert_equal 'test body',  @new_note.body
    assert_redirected_to note_path(@new_note)
  end

  should "edit a note" do
    get :edit, {id: @note.id}, {logged_in_id: @person.id}
    assert_response :success
    post :update, {
      id: @note.id,
      note: {title: 'test title', body: 'test body'}
    }, {logged_in_id: @person.id}
    assert_equal 'test title', @note.reload.title
    assert_equal 'test body',  @note.body
    assert_redirected_to note_path(@note)
  end

  should "not edit a note unless user is owner or admin" do
    get :edit, {id: @note.id}, {logged_in_id: @other_person.id}
    assert_response :unauthorized
    post :update, {
      id: @note.id,
      note: {title: 'test title', body: 'test body'}
    }, {logged_in_id: @other_person.id}
    assert_response :unauthorized
  end

  should "delete a personal note" do
    post :destroy, {id: @note.id}, {logged_in_id: @person.id}
    assert_raise(ActiveRecord::RecordNotFound) do
      @note.reload
    end
    assert_redirected_to person_path(@person, anchor: 'blog')
  end

  should "delete a group note" do
    @group = FactoryGirl.create(:group)
    @note.group = @group
    @note.save
    post :destroy, {id: @note.id}, {logged_in_id: @person.id}
    assert_raise(ActiveRecord::RecordNotFound) do
      @note.reload
    end
    assert_redirected_to group_path(@group, anchor: 'blog')
  end

  should "not delete a note unless user is owner or admin" do
    post :destroy, {id: @note.id}, {logged_in_id: @other_person.id}
    assert_response :unauthorized
  end

end
