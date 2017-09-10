require_relative '../rails_helper'

describe PicturesController, type: :controller do
  before do
    @person = FactoryGirl.create(:person)
    @album = FactoryGirl.create(:album, owner: @person)
    @picture = FactoryGirl.create(:picture, album: @album, person: @person)
  end

  def add_pictures(how_many = 2)
    @picture2 = FactoryGirl.create(:picture, album: @album, person: @person)
    @picture3 = FactoryGirl.create(:picture, album: @album, person: @person) unless how_many == 1
  end

  context '#index' do
    it 'redirects to album show page' do
      get :index,
          params: { album_id: @album.id },
          session: { logged_in_id: @person.id }
      expect(response).to redirect_to(@album)
    end
  end

  context '#show' do
    it 'should display a picture' do
      get :show,
          params: { album_id: @album.id, id: @picture.id },
          session: { logged_in_id: @person.id }
      expect(response).to be_success
      expect(assigns(:picture)).to eq(@picture)
    end
  end

  context '#next' do
    before do
      @picture2 = FactoryGirl.create(:picture, album: @album, person: @person)
    end

    it 'should redirect to next picture' do
      get :next,
          params: { album_id: @album.id, id: @picture.id },
          session: { logged_in_id: @person.id }
      expect(response).to redirect_to(album_picture_path(@album, @picture2))
    end

    context 'given specified picture is last in album' do
      before do
        get :next,
            params: { album_id: @album.id, id: @picture2.id },
            session: { logged_in_id: @person.id }
      end

      it 'should redirect to first picture' do
        expect(response).to redirect_to(album_picture_path(@album, @picture))
      end
    end
  end

  context '#prev' do
    before do
      @picture2 = FactoryGirl.create(:picture, album: @album, person: @person)
    end

    it 'should redirect to previous picture' do
      get :next,
          params: { album_id: @album.id, id: @picture2.id },
          session: { logged_in_id: @person.id }
      expect(response).to redirect_to(album_picture_path(@album, @picture))
    end

    context 'given specified picture is first in album' do
      before do
        get :next,
            params: { album_id: @album.id, id: @picture.id },
            session: { logged_in_id: @person.id }
      end

      it 'should redirect to last picture' do
        expect(response).to redirect_to(album_picture_path(@album, @picture2))
      end
    end
  end

  context '#create' do
    it 'should create one picture' do
      post :create,
           params: { album: @album.name, pictures: [Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/files/image.jpg'), 'image/jpeg', true)] },
           session: { logged_in_id: @person.id }
      expect(response).to redirect_to(@album)
      expect(flash[:notice]).to eq('1 picture(s) saved')
    end

    it 'should create more than one picture' do
      post :create,
           params: {
             album: @album.name,
             pictures: [
               Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/files/image.jpg'), 'image/jpeg', true),
               Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/files/image.jpg'), 'image/jpeg', true),
               Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/files/image.jpg'), 'image/jpeg', true)
             ]
           },
           session: { logged_in_id: @person.id }
      expect(response).to redirect_to(@album)
      expect(flash[:notice]).to eq('3 picture(s) saved')
    end

    it 'should create a new album by name' do
      post :create,
           params: { album: 'My Stuff', pictures: [Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/files/image.jpg'), 'image/jpeg', true)] },
           session: { logged_in_id: @person.id }
      album = Album.last
      expect(album.name).to eq('My Stuff')
      expect(response).to redirect_to(album)
      expect(flash[:notice]).to eq('1 picture(s) saved')
    end

    context 'given one bad image and one good image' do
      before do
        Picture.delete_all
        post :create,
             params: {
               album: 'My Stuff',
               pictures: [
                 Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/files/image.jpg'), 'image/jpeg', true),
                 Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/files/image.bmp'), 'image/bmp', true)
               ]
             },
             session: { logged_in_id: @person.id }
      end

      it 'should create one image and fail one image' do
        expect(Picture.count).to eq(1)
        expect(flash[:error]).to eq('image.bmp')
      end
    end

    context 'group specified' do
      before do
        @group = FactoryGirl.create(:group)
        @album = @group.albums.create(name: 'Existing Album')
      end

      context 'existing album name specified' do
        context 'user is not a group member' do
          it 'should return forbidden' do
            post :create,
                 params: { group_id: @group.id, album: 'Existing Album', pictures: [Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/files/image.jpg'), 'image/jpeg', true)] },
                 session: { logged_in_id: @person.id }
            expect(response).to be_forbidden
          end
        end

        context 'user is a group member' do
          before do
            @group.memberships.create(person: @person)
          end

          it 'should redirect to the album' do
            post :create,
                 params: { group_id: @group.id, album: 'Existing Album', pictures: [Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/files/image.jpg'), 'image/jpeg', true)] },
                 session: { logged_in_id: @person.id }
            expect(response).to redirect_to(assigns[:album])
          end

          context 'group does not allow pictures' do
            before do
              @group.update_attributes!(pictures: false)
            end

            it 'should return forbidden' do
              post :create,
                   params: { group_id: @group.id, album: 'Existing Album', pictures: [Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/files/image.jpg'), 'image/jpeg', true)] },
                   session: { logged_in_id: @person.id }
              expect(response).to be_forbidden
            end
          end
        end
      end
    end

    context 'group specified' do
      before do
        @group = FactoryGirl.create(:group)
      end

      context 'new album name specified' do
        context 'user is not a group member' do
          it 'should return forbidden' do
            post :create,
                 params: { group_id: @group.id, album: 'New Album', pictures: [Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/files/image.jpg'), 'image/jpeg', true)] },
                 session: { logged_in_id: @person.id }
            expect(response).to be_forbidden
          end

          it 'should not create an album' do
            expect(Album.where(name: 'New Album').first).to be_nil
          end
        end

        context 'user is a group member' do
          before do
            @group.memberships.create(person: @person)
          end

          it 'should redirect to the group' do
            post :create,
                 params: { group_id: @group.id, album: 'New Album', pictures: [Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/files/image.jpg'), 'image/jpeg', true)] },
                 session: { logged_in_id: @person.id }
            expect(response).to redirect_to(assigns[:album])
          end

          context 'group does not allow pictures' do
            before do
              @group.update_attributes!(pictures: false)
            end

            it 'should return forbidden' do
              post :create,
                   params: { group_id: @group.id, album: 'New Album', pictures: [Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/files/image.jpg'), 'image/jpeg', true)] },
                   session: { logged_in_id: @person.id }
              expect(response).to be_forbidden
            end

            it 'should not create an album' do
              expect(Album.where(name: 'New Album').first).to be_nil
            end
          end
        end
      end
    end

    it 'should use an existing album by name' do
      @album = @person.albums.create(name: 'Existing Album')
      album_count = Album.count
      post :create,
           params: { album: 'Existing Album', pictures: [Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/files/image.jpg'), 'image/jpeg', true)] },
           session: { logged_in_id: @person.id }
      expect(response).to redirect_to(@album)
      expect(Album.count).to eq(album_count)
      expect(Picture.last.album).to eq(@album)
      expect(flash[:notice]).to eq('1 picture(s) saved')
    end

    it 'should use an existing album by id' do
      @album = FactoryGirl.create(:album, owner: @person)
      album_count = Album.count
      post :create,
           params: { album_id: @album.id, pictures: [Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/files/image.jpg'), 'image/jpeg', true)] },
           session: { logged_in_id: @person.id }
      expect(response).to redirect_to(@album)
      expect(Album.count).to eq(album_count)
      expect(Picture.last.album).to eq(@album)
      expect(flash[:notice]).to eq('1 picture(s) saved')
    end
  end

  context '#update' do
    it 'should select a picture as an album cover' do
      add_pictures(1)
      post :update,
           params: { album_id: @album.id, id: @picture.id, cover: 'true' },
           session: { logged_in_id: @person.id }
      expect(response).to redirect_to(@album)
      expect(@picture.reload.cover).to be
      post :update,
           params: { album_id: @album.id, id: @picture2.id, cover: 'true' },
           session: { logged_in_id: @person.id }
      expect(response).to redirect_to(@album)
      expect(@picture.reload.cover).not_to be
      expect(@picture2.reload.cover).to be
    end

    it 'should rotate a picture' do
      @picture = FactoryGirl.create(:picture, :with_file, album: @album)
      post :update,
           params: { album_id: @album.id, id: @picture.id, degrees: '90' },
           session: { logged_in_id: @person.id }
      expect(response).to redirect_to(album_picture_path(@album, @picture))
    end
  end

  context '#destroy' do
    it 'should delete a picture' do
      post :destroy,
           params: { album_id: @album.id, id: @picture.id },
           session: { logged_in_id: @person.id }
      expect { @picture.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect(response).to redirect_to(album_path(@album))
    end
  end
end
