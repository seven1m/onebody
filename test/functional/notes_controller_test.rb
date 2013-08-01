require_relative '../test_helper'

class NotesControllerTest < ActionController::TestCase

  def setup
    @user = FactoryGirl.create(:person)
  end

  context '#index' do
    context 'nested route on person' do
      setup do
        @note = FactoryGirl.create(:note, person: @user)
      end

      should 'list all notes by person' do
        get :index, {person_id: @user.id}, {:logged_in_id => @user.id}
        assert_response :success
        assert_equal [@note], assigns(:notes)
      end
    end

    context 'nested route on group' do
      setup do
        @group = FactoryGirl.create(:group)
        @note = FactoryGirl.create(:note, group: @group, person: @user)
      end

      should 'list all notes by group' do
        get :index, {group_id: @group.id}, {:logged_in_id => @user.id}
        assert_response :success
        assert_equal [@note], assigns(:notes)
      end
    end
  end

  context '#show' do
    context 'note owned by user' do
      setup do
        @note = FactoryGirl.create(:note, person: @user)
      end

      should 'show note' do
        get :show, {id: @note.id}, {logged_in_id: @user.id}
        assert_response :success
        assert_equal @note, assigns(:note)
      end
    end

    context 'note owned by invisible person' do
      setup do
        @stranger = FactoryGirl.create(:person, visible: false)
        @note = FactoryGirl.create(:note, person: @stranger)
      end

      should 'not show note' do
        get :show, {id: @note.id}, {logged_in_id: @user.id}
        assert_response :forbidden
      end
    end
  end

  context '#new' do
    context 'shallow route' do
      setup do
        get :new, {person_id: @user.id}, {logged_in_id: @user.id}
      end

      should 'render template' do
        assert_response :success
        assert_template :new
      end
    end

    context 'nested route on a group' do
      setup do
        @group = FactoryGirl.create(:group)
        get :new, {group_id: @group.id}, {logged_in_id: @user.id}
      end

      should 'assign the group' do
        assert_equal @group, assigns[:note].group
      end
    end
  end

  context '#create' do
    setup do
      post :create, {note: {title: 'test title', body: 'test body'}, person_id: @user.id},
        {logged_in_id: @user.id}
    end

    should 'create a new personal note' do
      @note = Note.last
      assert_equal 'test title', @note.reload.title
      assert_equal 'test body',  @note.body
    end

    should 'redirect to the note' do
      assert_redirected_to note_path(Note.last)
    end
  end

  context '#edit' do
    context 'user is not owner' do
      setup do
        @note = FactoryGirl.create(:note)
        get :edit, {id: @note.id}, {logged_in_id: @user.id}
      end

      should 'return forbidden' do
        assert_response :forbidden
      end
    end

    context 'user is owner' do
      setup do
        @note = FactoryGirl.create(:note, person: @user)
        get :edit, {id: @note.id}, {logged_in_id: @user.id}
      end

      should 'render template' do
        assert_response :success
        assert_template :edit
      end
    end
  end

  context '#update' do
    context 'user is not owner' do
      setup do
        @note = FactoryGirl.create(:note)
        post :update, {id: @note.id, note: {title: 'test title', body: 'test body'}},
          {logged_in_id: @user.id}
      end

      should 'return forbidden' do
        assert_response :forbidden
      end
    end

    context 'user is owner' do
      setup do
        @note = FactoryGirl.create(:note, person: @user)
        post :update, {id: @note.id, note: {title: 'test title', body: 'test body'}},
          {logged_in_id: @user.id}
      end

      should 'update a note' do
        assert_equal 'test title', @note.reload.title
        assert_equal 'test body',  @note.body
      end

      should 'redirect to the note' do
        assert_redirected_to note_path(@note)
      end
    end
  end

  context '#destroy' do
    context 'user is not owner' do
      setup do
        @note = FactoryGirl.create(:note)
        post :destroy, {id: @note.id}, {logged_in_id: @user.id}
      end

      should 'return forbidden' do
        assert_response :forbidden
      end
    end

    context 'user is owner' do
      setup do
        @note = FactoryGirl.create(:note, person: @user)
        post :destroy, {id: @note.id}, {logged_in_id: @user.id}
      end

      should 'delete note' do
        assert_raise(ActiveRecord::RecordNotFound) do
          @note.reload
        end
      end

      should 'redirect to the listing of notes for the person' do
        assert_redirected_to person_notes_path(@user)
      end
    end

    context 'note is in a group' do
      setup do
        @group = FactoryGirl.create(:group)
        @note = FactoryGirl.create(:note, person: @user, group: @group)
        post :destroy, {id: @note.id}, {logged_in_id: @user.id}
      end

      should 'redirect to the listing of notes for the group' do
        assert_redirected_to group_notes_path(@group)
      end
    end

    context 'note belongs to someone else' do
      setup do
        @stranger = FactoryGirl.create(:person)
        @note = FactoryGirl.create(:note, person: @stranger)
        post :destroy, {id: @note.id}, {logged_in_id: @user.id}
      end

      should 'return forbidden' do
        assert_response :forbidden
      end
    end
  end

end
