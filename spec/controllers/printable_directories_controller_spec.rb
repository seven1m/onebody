require_relative '../rails_helper'

describe PrintableDirectoriesController, type: :controller do
  let(:user) { FactoryGirl.create(:person) }

  describe '#create' do
    before do
      allow(PrintableDirectoryJob).to receive(:perform_later)
      post :create, {}, logged_in_id: user.id
    end

    it 'calls perform_later on PrintableDirectoryJob' do
      expect(PrintableDirectoryJob).to have_received(:perform_later).with(
        Site.current,
        user.id,
        false
      )
    end

    it 'renders the create template' do
      expect(response).to render_template(:create)
    end
  end
end
