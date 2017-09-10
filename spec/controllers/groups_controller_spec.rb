require_relative '../rails_helper'

describe GroupsController, type: :controller do
  render_views

  before do
    @person, @other_person = FactoryGirl.create_list(:person, 2)
    @group = FactoryGirl.create(:group, name: 'Morgan Group', creator: @person, category: 'Small Groups')
    @group.memberships.create(person: @person, admin: true)
  end

  describe '#index' do
    context 'for a person' do
      before do
        get :index,
            params: { person_id: @person.id },
            session: { logged_in_id: @person.id }
      end

      it 'assigns the person' do
        expect(assigns(:person)).to eq(@person)
      end

      it 'renders the index_for_person template' do
        expect(response).to be_success
        expect(response).to render_template('index_for_person')
      end
    end

    context 'for a person with a hidden group' do
      before do
        @hidden_group = FactoryGirl.create(:group, hidden: true)
        @hidden_group.memberships.create!(person: @person)
      end

      context 'user is not an admin' do
        before do
          get :index,
              params: { person_id: @person.id },
              session: { logged_in_id: @person.id }
        end

        it 'does not list the hidden group' do
          expect(response.body).to_not match(/<tr.*hidden-group/)
        end
      end

      context 'user is admin with manage_groups privilege' do
        before do
          @person.admin = Admin.create(manage_groups: true)
          @person.save!
          get :index,
              params: { person_id: @person.id },
              session: { logged_in_id: @person.id }
        end

        it 'lists the hidden group' do
          expect(response.body).to match(/<tr.*hidden-group/)
        end
      end
    end

    context 'for a category' do
      before do
        get :index,
            params: { category: 'Small Groups' },
            session: { logged_in_id: @person.id }
      end

      it 'assigns groups matching the category' do
        expect(assigns(:groups).to_a).to eq([@group])
      end

      it 'renders the search template' do
        expect(response).to be_success
        expect(response).to render_template('search')
      end
    end

    context 'for a group name' do
      before do
        get :index,
            params: { name: 'Morgan' },
            session: { logged_in_id: @person.id }
      end

      it 'assigns groups matching the name' do
        expect(assigns(:groups).to_a).to eq([@group])
      end

      it 'renders the search template' do
        expect(response).to be_success
        expect(response).to render_template('search')
      end
    end

    context 'overview page' do
      before do
        get :index,
            session: { logged_in_id: @person.id }
      end

      it 'assigns categories' do
        expect(assigns(:categories)).to eq(['Small Groups'])
      end

      it 'renders the index template' do
        expect(response).to be_success
        expect(response).to render_template('index')
      end
    end

    context 'overview page with an unapproved group' do
      before do
        @unapproved_group = FactoryGirl.create(:group, approved: false, creator: @person)
      end

      context 'user is group creator' do
        before do
          get :index,
              session: { logged_in_id: @person.id }
        end

        it 'assigns the unapproved group' do
          expect(assigns(:unapproved_groups)).to eq([@unapproved_group])
        end
      end

      context 'user is not group creator' do
        before do
          get :index,
              session: { logged_in_id: @other_person.id }
        end

        it 'does not assign the unapproved group' do
          expect(assigns(:unapproved_groups)).to eq([])
        end
      end

      context 'user is admin with manage_groups privilege' do
        before do
          @person.admin = Admin.create(manage_groups: true)
          @person.save!
          get :index,
              session: { logged_in_id: @person.id }
        end

        it 'assigns the unapproved group' do
          expect(assigns(:unapproved_groups)).to eq([@unapproved_group])
        end
      end
    end
  end

  describe '#show' do
    context 'group is not private' do
      before do
        get :show,
            params: { id: @group.id },
            session: { logged_in_id: @person.id }
      end

      it 'renders the show template' do
        expect(response).to be_success
        expect(response).to render_template('show')
      end
    end

    context 'group is private' do
      before do
        @group.update_attribute(:private, true)
      end

      context 'user is a member' do
        before do
          get :show,
              params: { id: @group.id },
              session: { logged_in_id: @person.id }
        end

        it 'renders the show template' do
          expect(response).to be_success
          expect(response).to render_template('show')
        end
      end

      context 'user is not a member' do
        before do
          get :show,
              params: { id: @group.id },
              session: { logged_in_id: @other_person.id }
        end

        it 'renders the show template' do
          expect(response).to be_success
          expect(response).to render_template('show_limited')
        end
      end
    end

    context 'group is hidden' do
      before do
        @group.update_attribute(:hidden, true)
      end

      context 'user is a member' do
        before do
          get :show,
              params: { id: @group.id },
              session: { logged_in_id: @person.id }
        end

        it 'renders the show template' do
          expect(response).to be_success
          expect(response).to render_template('show')
        end
      end

      context 'user is not a member' do
        before do
          get :show,
              params: { id: @group.id },
              session: { logged_in_id: @other_person.id }
        end

        it 'renders the show template (this may change in the future)' do
          expect(response).to be_success
          expect(response).to render_template('show_limited')
        end
      end

      context 'user is an admin who can manage groups' do
        before do
          @person.admin = Admin.create(manage_groups: true)
          @person.save!
          get :show,
              params: { id: @group.id },
              session: { logged_in_id: @person.id }
        end

        it 'renders the show template' do
          expect(response).to be_success
          expect(response).to render_template('show')
        end
      end
    end
  end

  context '#update' do
    context 'given a photo file' do
      before do
        post :update,
             params: {
               id: @group.id,
               group: {
                 photo: Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/files/image.jpg'), 'image/jpeg', true)
               }
             },
             session: { logged_in_id: @person.id }
      end

      it 'saves the photo' do
        expect(@group.reload.photo.exists?).to eq(true)
      end

      it 'redirects to the group page' do
        expect(response).to redirect_to(group_path(@group))
      end
    end

    context 'given photo="remove"' do
      before do
        @group.photo = File.open(Rails.root.join('spec/fixtures/files/image.jpg'))
        @group.save!
        post :update,
             params: { id: @group.id, group: { photo: 'remove' } },
             session: { logged_in_id: @person.id }
      end

      it 'removes the photo' do
        expect(@group.reload.photo.exists?).to eq(false)
      end

      it 'redirects to the group page' do
        expect(response).to redirect_to(group_path(@group))
      end
    end
  end

  describe '#edit' do
    context 'user is group admin' do
      before do
        get :edit,
            params: { id: @group.id },
            session: { logged_in_id: @person.id }
      end

      it 'renders the edit template' do
        expect(response).to be_success
        expect(response).to render_template('edit')
      end
    end

    context 'user is admin with manage_groups privilege' do
      before do
        @other_person.admin = Admin.create!(manage_groups: true)
        @other_person.save!
        get :edit,
            params: { id: @group.id },
            session: { logged_in_id: @other_person.id }
      end

      it 'renders the edit template' do
        expect(response).to be_success
        expect(response).to render_template('edit')
      end
    end

    context 'user is not group admin' do
      before do
        get :edit,
            params: { id: @group.id },
            session: { logged_in_id: @other_person.id }
      end

      it 'returns unauthorized' do
        expect(response.status).to eq(401)
      end
    end
  end

  describe '#update' do
    context 'user is group admin' do
      before do
        put :update,
            params: {
              id: @group.id,
              group: {
                name: 'test name',
                category: 'test cat'
              }
            },
            session: { logged_in_id: @person.id }
      end

      it 'updates the group' do
        expect(@group.reload.attributes).to include(
          'name'     => 'test name',
          'category' => 'test cat'
        )
      end

      it 'redirect to the group page' do
        expect(response).to redirect_to(group_path(@group))
      end
    end

    context 'user is not group admin' do
      before do
        put :update,
            params: {
              id: @group.id,
              group: {
                name: 'test name',
                category: 'test cat'
              }
            },
            session: { logged_in_id: @other_person.id }
      end

      it 'returns unauthorized' do
        expect(response.status).to eq(401)
      end
    end
  end

  describe '#batch' do
    before do
      @admin = FactoryGirl.create(:person, :admin_manage_groups)
      @group2 = FactoryGirl.create(:group)
    end

    context 'GET' do
      before do
        get :batch,
            session: { logged_in_id: @admin.id }
      end

      it 'renders the batch template' do
        expect(response).to be_success
        expect(response).to render_template(:batch)
      end
    end

    context 'POST' do
      context 'given valid data' do
        before do
          post :batch,
               params: {
                 groups: {
                   @group.id.to_s => {
                     name: 'foobar',
                     members_send: '0'
                   },
                   @group2.id.to_s => {
                     address: 'baz'
                   }
                 }
               },
               session: { logged_in_id: @admin.id }
        end

        it 'renders the batch template again' do
          expect(response).to be_success
          expect(response).to render_template(:batch)
        end

        it 'updates the groups' do
          expect(@group.reload.name).to eq('foobar')
          expect(@group).to_not be_members_send
          expect(@group2.reload.address).to eq('baz')
        end
      end

      context 'given invalid data' do
        before do
          post :batch,
               params: {
                 groups: {
                   @group.id.to_s => {
                     address: 'bad*address'
                   }
                 }
               },
               session: { logged_in_id: @admin.id }
        end

        it 'shows errors' do
          expect(response.body).to include(
            I18n.t('activerecord.errors.models.group.attributes.address.invalid')
          )
        end
      end
    end

    context 'POST via ajax' do
      context 'given valid data' do
        before do
          post :batch,
               params: {
                 format: 'js',
                 groups: {
                   @group.id.to_s => {
                     name: 'lorem',
                     members_send: 'true'
                   },
                   @group2.id.to_s => {
                     address: 'ipsum'
                   }
                 }
               },
               session: { logged_in_id: @admin.id }
        end

        it 'updates the groups' do
          expect(@group.reload.name).to eq('lorem')
          expect(@group).to be_members_send
          expect(@group2.reload.address).to eq('ipsum')
        end
      end

      context 'given invalid data' do
        before do
          post :batch,
               params: {
                 format: 'js',
                 groups: {
                   @group.id.to_s => {
                     address: 'bad*address'
                   }
                 }
               },
               session: { logged_in_id: @admin.id }
        end

        it 'shows errors' do
          expect(@response.body).to match(/\$\("#group#{@group.id}"\)\.addClass\('error'\)/)
        end
      end
    end
  end

  describe '#new' do
    before do
      get :new,
          session: { logged_in_id: @person.id }
    end

    it 'renders the new group form' do
      expect(response).to render_template(:new)
    end
  end

  context '#create' do
    context 'user is not an admin' do
      before do
        post :create,
             params: { group: { name: 'test name', category: 'test cat' } },
             session: { logged_in_id: @person.id }
        @group = Group.last
      end

      it 'creates the group' do
        expect(@group.attributes).to include(
          'name'     => 'test name',
          'category' => 'test cat'
        )
      end

      it 'does not mark the group as approved' do
        expect(@group).to_not be_approved
      end

      it 'adds the creator as a group member' do
        expect(@person.member_of?(@group)).to eq(true)
      end

      it "redirects to the group's URL" do
        expect(response).to redirect_to(group_path(Group.last))
      end
    end

    context 'user is an admin' do
      before do
        @person.admin = Admin.create(manage_groups: true)
        @person.save!
        post :create,
             params: { group: { name: 'test name', category: 'test cat' } },
             session: { logged_in_id: @person.id }
        @group = Group.last
      end

      it 'creates the group' do
        expect(@group.attributes).to include(
          'name'     => 'test name',
          'category' => 'test cat'
        )
      end

      it 'marks the group as approved' do
        expect(@group).to be_approved
      end

      it 'does not add the creator as a group member' do
        expect(@person.member_of?(@group)).to eq(false)
      end

      it "redirects to the group's URL" do
        expect(response).to redirect_to(group_path(Group.last))
      end
    end
  end
end
