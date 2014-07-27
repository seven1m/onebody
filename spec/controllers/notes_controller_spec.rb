require_relative '../spec_helper'

describe NotesController do

  before do
    @user = FactoryGirl.create(:person)
  end

  context '#index' do
    before do
      @note = FactoryGirl.create(:note, person: @user)
    end

    it 'should list all notes by person' do
      get :index, {person_id: @user.id}, {:logged_in_id => @user.id}
      expect(response).to be_success
      expect(assigns(:notes)).to eq([@note])
    end
  end

  context '#show' do
    context 'note owned by user' do
      before do
        @note = FactoryGirl.create(:note, person: @user)
      end

      it 'should show note' do
        get :show, {id: @note.id}, {logged_in_id: @user.id}
        expect(response).to be_success
        expect(assigns(:note)).to eq(@note)
      end
    end

    context 'note owned by invisible person' do
      before do
        @stranger = FactoryGirl.create(:person, visible: false)
        @note = FactoryGirl.create(:note, person: @stranger)
      end

      it 'should not show note' do
        get :show, {id: @note.id}, {logged_in_id: @user.id}
        expect(response).to be_forbidden
      end
    end
  end

  context '#new' do
    before do
      get :new, {person_id: @user.id}, {logged_in_id: @user.id}
    end

    it 'should render template' do
      expect(response).to be_success
      expect(response).to render_template(:new)
    end
  end

  context '#create' do
    before do
      post :create, {note: {title: 'test title', body: 'test body'}, person_id: @user.id},
        {logged_in_id: @user.id}
    end

    it 'should create a new personal note' do
      @note = Note.last
      expect(@note.reload.title).to eq("test title")
      expect(@note.body).to eq("test body")
    end

    it 'should redirect to the note' do
      expect(response).to redirect_to(note_path(Note.last))
    end
  end

  context '#edit' do
    context 'user is not owner' do
      before do
        @note = FactoryGirl.create(:note)
        get :edit, {id: @note.id}, {logged_in_id: @user.id}
      end

      it 'should return forbidden' do
        expect(response).to be_forbidden
      end
    end

    context 'user is owner' do
      before do
        @note = FactoryGirl.create(:note, person: @user)
        get :edit, {id: @note.id}, {logged_in_id: @user.id}
      end

      it 'should render template' do
        expect(response).to be_success
        expect(response).to render_template(:edit)
      end
    end
  end

  context '#update' do
    context 'user is not owner' do
      before do
        @note = FactoryGirl.create(:note)
        post :update, {id: @note.id, note: {title: 'test title', body: 'test body'}},
          {logged_in_id: @user.id}
      end

      it 'should return forbidden' do
        expect(response).to be_forbidden
      end
    end

    context 'user is owner' do
      before do
        @note = FactoryGirl.create(:note, person: @user)
        post :update, {id: @note.id, note: {title: 'test title', body: 'test body'}},
          {logged_in_id: @user.id}
      end

      it 'should update a note' do
        expect(@note.reload.title).to eq("test title")
        expect(@note.body).to eq("test body")
      end

      it 'should redirect to the note' do
        expect(response).to redirect_to(note_path(@note))
      end
    end
  end

  context '#destroy' do
    context 'user is not owner' do
      before do
        @note = FactoryGirl.create(:note)
        post :destroy, {id: @note.id}, {logged_in_id: @user.id}
      end

      it 'should return forbidden' do
        expect(response).to be_forbidden
      end
    end

    context 'user is owner' do
      before do
        @note = FactoryGirl.create(:note, person: @user)
        post :destroy, {id: @note.id}, {logged_in_id: @user.id}
      end

      it 'should delete note' do
        expect { @note.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it 'should redirect to the listing of notes for the person' do
        expect(response).to redirect_to(person_notes_path(@user))
      end
    end

    context 'note belongs to someone else' do
      before do
        @stranger = FactoryGirl.create(:person)
        @note = FactoryGirl.create(:note, person: @stranger)
        post :destroy, {id: @note.id}, {logged_in_id: @user.id}
      end

      it 'should return forbidden' do
        expect(response).to be_forbidden
      end
    end
  end

end
