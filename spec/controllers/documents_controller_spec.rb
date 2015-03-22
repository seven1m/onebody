require_relative '../rails_helper'

describe DocumentsController, type: :controller do
  let(:user)      { FactoryGirl.create(:person) }
  let(:file_path) { Rails.root.join('spec/fixtures/files/attachment.pdf') }
  let(:file)      { Rack::Test::UploadedFile.new(file_path, 'application/pdf', true) }

  before do
    Setting.set(:features, :documents, true)
  end

  describe '#index' do
    let!(:top_folder)          { FactoryGirl.create(:document_folder) }
    let!(:top_folder_hidden)   { FactoryGirl.create(:document_folder, hidden: true) }
    let!(:top_document)        { FactoryGirl.create(:document) }
    let!(:child_folder)        { FactoryGirl.create(:document_folder, folder_id: top_folder.id) }
    let!(:child_folder_hidden) { FactoryGirl.create(:document_folder, folder_id: top_folder.id, hidden: true) }
    let!(:child_document)      { FactoryGirl.create(:document, folder_id: top_folder.id) }

    context 'user is not an admin' do
      context 'at top level' do
        before do
          get :index, {}, { logged_in_id: user.id }
        end

        it 'lists active (not hidden) folders' do
          expect(assigns[:folders]).to eq([top_folder])
        end

        it 'lists documents' do
          expect(assigns[:documents]).to eq([top_document])
        end
      end

      context 'at top level with a group-only folder' do
        let!(:group)            { FactoryGirl.create(:group) }
        let!(:folder_for_group) { FactoryGirl.create(:document_folder, group_ids: [group.id]) }

        context 'user is not a member of the group' do
          before do
            get :index, {}, { logged_in_id: user.id }
          end

          it 'does not list the folder' do
            expect(assigns[:folders]).to eq([top_folder])
          end
        end

        context 'user is a member of the group' do
          let!(:membership) { group.memberships.create!(person: user) }

          before do
            get :index, { restricted_folders: 'true' }, { logged_in_id: user.id }
          end

          it 'lists the folder' do
            expect(assigns[:folders]).to match_array([top_folder, folder_for_group])
          end
        end
      end

      context 'viewing a folder' do
        before do
          get :index, { folder_id: top_folder.id }, { logged_in_id: user.id }
        end

        it 'lists active (not hidden) folders' do
          expect(assigns[:folders]).to eq([child_folder])
        end

        it 'lists documents' do
          expect(assigns[:documents]).to eq([child_document])
        end
      end

      context 'viewing a hidden folder' do
        it 'returns a 404' do
          expect {
            get :index, { folder_id: top_folder_hidden.id }, { logged_in_id: user.id }
          }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context 'viewing a folder for a group the user is not a member of' do
        let!(:group)            { FactoryGirl.create(:group) }
        let!(:folder_for_group) { FactoryGirl.create(:document_folder, group_ids: [group.id]) }

        it 'returns a 404' do
          expect {
            get :index, { folder_id: folder_for_group.id }, { logged_in_id: user.id }
          }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context 'viewing a folder for a group the user is a member of' do
        let!(:group)            { FactoryGirl.create(:group) }
        let!(:folder_for_group) { FactoryGirl.create(:document_folder, group_ids: [group.id]) }
        let!(:membership)       { group.memberships.create!(person: user) }

        it 'returns 200 and shows the template' do
          get :index, { folder_id: folder_for_group.id }, { logged_in_id: user.id }
          expect(response.status).to eq(200)
          expect(response).to render_template(:index)
        end
      end
    end

    context 'user is an admin' do
      before do
        user.admin = Admin.create(manage_documents: true)
        user.save!
      end

      context 'at top level' do
        before do
          get :index, { hidden_folders: 'true' }, { logged_in_id: user.id }
        end

        it 'lists all folders' do
          expect(assigns[:folders]).to match_array([top_folder, top_folder_hidden])
        end
      end

      context 'viewing a folder' do
        before do
          get :index, { folder_id: top_folder.id, hidden_folders: 'true' }, { logged_in_id: user.id }
        end

        it 'lists all folders' do
          expect(assigns[:folders]).to match_array([child_folder, child_folder_hidden])
        end
      end
    end
  end

  describe '#show' do
    let(:document) { FactoryGirl.create(:document) }

    context 'user is not an admin' do
      context 'document is not in a hidden folder' do
        before do
          get :show, { id: document.id }, { logged_in_id: user.id }
        end

        it 'gets the document' do
          expect(assigns[:document]).to eq(document)
        end

        it 'renders the show template' do
          expect(response).to render_template('show')
        end
      end

      context 'document is in a hidden folder' do
        before do
          document.folder = FactoryGirl.create(:document_folder, hidden: true)
          document.save!
        end

        it 'returns a 404' do
          expect {
            get :show, { id: document.id }, { logged_in_id: user.id }
          }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context 'document is in a folder for a group' do
        let!(:group)            { FactoryGirl.create(:group) }
        let!(:folder_for_group) { FactoryGirl.create(:document_folder, group_ids: [group.id]) }

        before do
          document.folder = folder_for_group
          document.save!
        end

        context 'user is not a member of the group' do
          it 'returns a 404' do
            expect {
              get :show, { id: document.id }, { logged_in_id: user.id }
            }.to raise_error(ActiveRecord::RecordNotFound)
          end
        end

        context 'user is a member of the group' do
          let!(:membership) { group.memberships.create!(person: user) }

          it 'returns a 200 and renders the page' do
            get :show, { id: document.id }, { logged_in_id: user.id }
            expect(response.status).to eq(200)
            expect(response).to render_template(:show)
          end
        end
      end
    end

    context 'user an admin' do
      before do
        user.admin = Admin.create(manage_documents: true)
        user.save!
      end

      context 'document is not in a hidden folder' do
        before do
          get :show, { id: document.id }, { logged_in_id: user.id }
        end

        it 'gets the document' do
          expect(assigns[:document]).to eq(document)
        end

        it 'renders the show template' do
          expect(response).to render_template('show')
        end
      end

      context 'document is in a hidden folder' do
        before do
          document.folder = FactoryGirl.create(:document_folder, hidden: true)
          document.save!
          get :show, { id: document.id }, { logged_in_id: user.id }
        end

        it 'gets the document' do
          expect(assigns[:document]).to eq(document)
        end

        it 'renders the show template' do
          expect(response).to render_template('show')
        end
      end
    end
  end

  describe '#new' do
    context 'user is an admin' do
      before do
        user.admin = Admin.create(manage_documents: true)
        user.save!
      end

      context 'new folder' do
        context 'at top level' do
          before do
            get :new, { folder: true }, { logged_in_id: user.id }
          end

          it 'builds a new folder' do
            expect(assigns[:folder]).to be_new_record
          end

          it 'renders new_folder template' do
            expect(response).to render_template('new_folder')
          end
        end

        context 'inside a folder' do
          let(:top_folder) { FactoryGirl.create(:document_folder) }

          before do
            get :new, { folder: true, folder_id: top_folder.id }, { logged_in_id: user.id }
          end

          it 'associates the folder with the parent folder' do
            expect(assigns[:folder].folder_id).to eq(top_folder.id)
          end
        end
      end

      context 'new document' do
        context 'at top level' do
          before do
            get :new, {}, { logged_in_id: user.id }
          end

          it 'builds a new document' do
            expect(assigns[:document]).to be_new_record
          end

          it 'renders new template' do
            expect(response).to render_template('new')
          end
        end

        context 'inside a folder' do
          let(:top_folder) { FactoryGirl.create(:document_folder) }

          before do
            get :new, { folder_id: top_folder.id }, { logged_in_id: user.id }
          end

          it 'associates the document with the parent folder' do
            expect(assigns[:document].folder_id).to eq(top_folder.id)
          end
        end
      end
    end
  end

  describe '#create' do
    context 'user is an admin' do
      before do
        user.admin = Admin.create(manage_documents: true)
        user.save!
      end

      context 'new folder' do
        context 'at top level' do
          context 'given proper params' do
            before do
              post :create, {
                folder: {
                  name: 'Test Folder',
                  description: 'description of folder'
                }
              }, { logged_in_id: user.id }
            end

            it 'creates a new folder' do
              expect(assigns[:folder].reload).to be
              expect(assigns[:folder].name).to eq('Test Folder')
              expect(assigns[:folder].description).to eq('description of folder')
            end

            it 'redirects to the folder' do
              expect(response).to redirect_to(documents_path(folder_id: assigns[:folder].id))
            end

            it 'sets a flash notice' do
              expect(flash[:notice]).to be
            end
          end

          context 'given missing params' do
            render_views

            before do
              post :create, { folder: { description: 'description of folder' } }, { logged_in_id: user.id }
            end

            it 'renders the new_folder template, showing the errors' do
              expect(response).to render_template('new_folder')
              expect(response.body).to match(/there were errors/i)
            end
          end
        end

        context 'inside a folder' do
          let(:top_folder) { FactoryGirl.create(:document_folder) }

          context 'given proper params' do
            before do
              post :create, {
                folder: {
                  folder_id: top_folder.id,
                  name: 'Child Folder',
                  description: 'description of folder'
                }
              }, { logged_in_id: user.id }
            end

            it 'associates parent folder' do
              expect(assigns[:folder].folder_id).to eq(top_folder.id)
            end
          end
        end

        context 'given group_ids param' do
          let(:group) { FactoryGirl.create(:group) }

          before do
            post :create, {
              folder: {
                name: 'Test Folder',
                description: 'description of folder',
                group_ids: [group.id]
              }
            }, { logged_in_id: user.id }
            @folder = DocumentFolder.last
          end

          it 'creates associated DocumentFolderGroup records' do
            expect(@folder.reload.document_folder_groups.count).to eq(1)
            expect(@folder.groups.first).to eq(group)
          end
        end
      end

      context 'new document' do
        context 'at top level' do
          context 'given proper params' do
            before do
              post :create, {
                document: {
                  name:        'Test Document',
                  description: 'description of document',
                  file:        file
                }
              }, { logged_in_id: user.id }
            end

            it 'creates a new document' do
              expect(assigns[:document].reload).to be
              expect(assigns[:document].name).to eq('Test Document')
              expect(assigns[:document].description).to eq('description of document')
            end

            it 'attaches the file' do
              expect(assigns[:document].reload.file).to exist
              expect(assigns[:document].file_file_name).to eq(file.original_filename)
              expect(assigns[:document].file.size).to eq(file.size)
            end

            it 'redirects to the document' do
              expect(response).to redirect_to(document_path(assigns[:document].id))
            end

            it 'sets a flash notice' do
              expect(flash[:notice]).to be
            end
          end

          context 'given missing params' do
            render_views

            before do
              post :create, { document: { description: 'description of document' } }, { logged_in_id: user.id }
            end

            it 'renders the new template, showing the errors' do
              expect(response).to render_template('new')
              expect(response.body).to match(/there were errors/i)
            end
          end
        end

        context 'inside a folder' do
          let(:top_folder) { FactoryGirl.create(:document_folder) }

          context 'given proper params' do
            before do
              post :create, {
                document: {
                  folder_id: top_folder.id,
                  name: 'Child Document',
                  description: 'description of document'
                }
              }, { logged_in_id: user.id }
            end

            it 'associates parent folder' do
              expect(assigns[:document].folder_id).to eq(top_folder.id)
            end
          end
        end
      end
    end
  end

  describe '#edit' do
    context 'user is an admin' do
      before do
        user.admin = Admin.create(manage_documents: true)
        user.save!
      end

      context 'document' do
        before do
          @document = FactoryGirl.create(:document)
          get :edit, { id: @document.id }, { logged_in_id: user.id }
        end

        it 'renders the edit template' do
          expect(response).to render_template('edit')
        end
      end

      context 'folder' do
        before do
          @folder = FactoryGirl.create(:document_folder)
          get :edit, { id: @folder.id, folder: true }, { logged_in_id: user.id }
        end

        it 'renders the edit_folder template' do
          expect(response).to render_template('edit_folder')
        end
      end
    end
  end

  describe '#update' do
    context 'user is an admin' do
      before do
        user.admin = Admin.create(manage_documents: true)
        user.save!
      end

      context 'document' do
        before do
          @document = FactoryGirl.create(:document)
        end

        context 'updating name' do
          before do
            put :update, { id: @document.id, document: { name: 'New Name' } }, { logged_in_id: user.id }
          end

          it 'updates the document' do
            expect(assigns[:document].reload.name).to eq('New Name')
          end

          it 'redirects to the parent folder with a notice' do
            expect(response).to redirect_to(documents_path)
            expect(flash[:notice]).to be
          end
        end

        context 'changing parent folder' do
          before do
            @folder = FactoryGirl.create(:document_folder)
            put :update, { id: @document.id, document: { folder_id: @folder.id } }, { logged_in_id: user.id }
          end

          it 'updates the document folder' do
            expect(assigns[:document].reload.folder).to eq(@folder)
          end

          it 'redirects to the parent folder with a notice' do
            expect(response).to redirect_to(documents_path(folder_id: @folder))
            expect(flash[:notice]).to be
          end
        end
      end

      context 'folder' do
        before do
          @folder = FactoryGirl.create(:document_folder)
        end

        context 'given proper params' do
          before do
            put :update, { id: @folder.id, folder: { name: 'New Name' } }, { logged_in_id: user.id }
          end

          it 'updates the folder' do
            expect(assigns[:folder].reload.name).to eq('New Name')
          end

          it 'redirects to the parent folder with a notice' do
            expect(response).to redirect_to(documents_path)
            expect(flash[:notice]).to be
          end
        end

        context 'given invalid params' do
          render_views

          before do
            put :update, { id: @folder.id, folder: { name: 'x' * 500 } }, { logged_in_id: user.id }
          end

          it 'renders the edit_folder template' do
            expect(response).to render_template('edit_folder')
          end

          it 'shows errors' do
            expect(response.body).to match(/there were errors/i)
          end
        end

        context 'given group_ids param' do
          let(:group) { FactoryGirl.create(:group) }

          before do
            put :update, {
              id: @folder.id,
              folder: {
                name: 'Foo',
                group_ids: [group.id]
              }
            }, { logged_in_id: user.id }
          end

          it 'creates associated DocumentFolderGroup records' do
            expect(@folder.reload.document_folder_groups.count).to eq(1)
            expect(@folder.groups.first).to eq(group)
          end
        end
      end
    end
  end

  describe '#destroy' do
    context 'user is an admin' do
      before do
        user.admin = Admin.create(manage_documents: true)
        user.save!
      end

      context 'document' do
        let(:document) { FactoryGirl.create(:document) }

        before do
          delete :destroy, { id: document.id }, { logged_in_id: user.id }
        end

        it 'deletes the document' do
          expect { document.reload }.to raise_error(ActiveRecord::RecordNotFound)
        end

        it 'redirects to the parent folder with a notice' do
          expect(response).to redirect_to(documents_path)
          expect(flash[:notice]).to be
        end
      end

      context 'folder' do
        let!(:folder)         { FactoryGirl.create(:document_folder) }
        let!(:child_folder)   { FactoryGirl.create(:document_folder, folder_id: folder.id) }
        let!(:child_document) { FactoryGirl.create(:document, folder_id: folder.id) }

        before do
          delete :destroy, { id: folder.id, folder: true }, { logged_in_id: user.id }
        end

        it 'deletes the folder' do
          expect { folder.reload }.to raise_error(ActiveRecord::RecordNotFound)
        end

        it 'deletes all children' do
          expect { child_folder.reload   }.to raise_error(ActiveRecord::RecordNotFound)
          expect { child_document.reload }.to raise_error(ActiveRecord::RecordNotFound)
        end

        it 'redirects to the parent folder with a notice' do
          expect(response).to redirect_to(documents_path)
          expect(flash[:notice]).to be
        end
      end
    end
  end

  describe '#download' do
    let(:document) { FactoryGirl.create(:document) }

    before do
      document.file = file
      document.save
    end

    context 'user is not an admin' do
      context 'document is not in a hidden folder' do
        before do
          get :download, { id: document.id }, { logged_in_id: user.id }
        end

        it 'returns the file data' do
          expect(response.body).to eq(file.read)
        end

        it 'sets the content type' do
          expect(response.content_type).to eq('application/pdf')
        end

        it 'sets the download filename' do
          expect(response['Content-Disposition']).to eq('attachment; filename="attachment.pdf"')
        end
      end

      context 'document is in a hidden folder' do
        before do
          document.folder = FactoryGirl.create(:document_folder, hidden: true)
          document.save!
        end

        it 'returns a 404' do
          expect {
            get :download, { id: document.id }, { logged_in_id: user.id }
          }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context 'document is in a folder for a group' do
        let!(:group)            { FactoryGirl.create(:group) }
        let!(:folder_for_group) { FactoryGirl.create(:document_folder, group_ids: [group.id]) }

        before do
          document.folder = folder_for_group
          document.save!
        end

        context 'user is not a member of the group' do
          it 'returns a 404' do
            expect {
              get :download, { id: document.id }, { logged_in_id: user.id }
            }.to raise_error(ActiveRecord::RecordNotFound)
          end
        end

        context 'user is a member of the group' do
          let!(:membership) { group.memberships.create!(person: user) }

          it 'returns a 200' do
            get :download, { id: document.id }, { logged_in_id: user.id }
            expect(response.status).to eq(200)
          end
        end
      end
    end

    context 'user is an admin' do
      before do
        user.admin = Admin.create(manage_documents: true)
        user.save!
      end

      context 'document is not in a hidden folder' do
        before do
          get :download, { id: document.id }, { logged_in_id: user.id }
        end

        it 'returns the file data' do
          expect(response.body).to eq(file.read)
        end
      end

      context 'document is in a hidden folder' do
        before do
          document.folder = FactoryGirl.create(:document_folder, hidden: true)
          document.save!
          get :download, { id: document.id }, { logged_in_id: user.id }
        end

        it 'returns the file data' do
          expect(response.body).to eq(file.read)
        end
      end
    end
  end
end
