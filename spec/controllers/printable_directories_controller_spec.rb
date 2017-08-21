require_relative '../rails_helper'

describe PrintableDirectoriesController, type: :controller do
  let(:user) { FactoryGirl.create(:person) }

  describe '#create' do
    before do
      allow(PrintableDirectoryJob).to receive(:perform_later)
      post :create,
           session: { logged_in_id: user.id }
    end

    it 'calls perform_later on PrintableDirectoryJob' do
      expect(PrintableDirectoryJob).to have_received(:perform_later).with(
        Site.current,
        user.id,
        Integer,
        false
      )
    end

    it 'redirects to the show action' do
      expect(response).to redirect_to(printable_directory_path(GeneratedFile.last))
    end
  end
end
