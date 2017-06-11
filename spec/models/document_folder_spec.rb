require_relative '../rails_helper'

describe DocumentFolder do
  describe 'validations' do
    context 'given folder_id set to self' do
      let(:folder) { FactoryGirl.create(:document_folder) }

      before do
        folder.folder_id = folder.id
      end

      it 'is invalid' do
        expect(folder).to_not be_valid
      end

      it 'has an error on folder_id' do
        folder.valid?
        expect(folder.errors[:folder_id]).to_not be_empty
      end
    end

    context 'given folder_id set to a child of this folder' do
      let(:grandfather) { FactoryGirl.create(:document_folder) }
      let(:father) { FactoryGirl.create(:document_folder, folder_id: grandfather.id) }
      let(:son) { FactoryGirl.create(:document_folder, folder_id: father.id) }

      before do
        grandfather.folder_id = son.id
      end

      it 'is invalid' do
        expect(grandfather).to_not be_valid
      end

      it 'has an error on folder_id' do
        grandfather.valid?
        expect(grandfather.errors[:folder_id]).to_not be_empty
      end
    end

    context 'given folder is nested too deep' do
      let(:folder) { FactoryGirl.build(:document_folder) }

      before do
        # simulate a large ancestor list
        folder.parent_folder_ids = (1..1001).to_a
      end

      it 'is invalid' do
        expect(folder).to_not be_valid
      end

      it 'has an error on parent_folder_ids' do
        folder.valid?
        expect(folder.errors[:parent_folder_ids]).to_not be_empty
      end
    end
  end

  describe 'path' do
    context 'no parents' do
      let(:folder) { FactoryGirl.create(:document_folder) }

      it 'has a path the same as its name' do
        expect(folder.path).to eq(folder.name)
      end
    end

    context 'not too long' do
      let(:grandfather) { FactoryGirl.create(:document_folder, name: 'Grandfather Folder') }
      let(:father) { FactoryGirl.create(:document_folder, folder_id: grandfather.id, name: 'Father Folder') }
      let(:son) { FactoryGirl.create(:document_folder, folder_id: father.id, name: 'Son Folder') }

      it 'builds its path based on the parent folder names' do
        expect(son.path).to eq('Grandfather Folder > Father Folder > Son Folder')
      end
    end

    context 'path is too long' do
      let(:level1) { FactoryGirl.create(:document_folder, name: 'w' * 255) }
      let(:level2) { FactoryGirl.create(:document_folder, folder_id: level1.id, name: 'x' * 255) }
      let(:level3) { FactoryGirl.create(:document_folder, folder_id: level2.id, name: 'y' * 255) }
      let(:level4) { FactoryGirl.create(:document_folder, folder_id: level3.id, name: 'z' * 255) }
      let(:level5) { FactoryGirl.create(:document_folder, folder_id: level4.id, name: 'z' * 255) }

      it 'shortes to 997 characters and prepends with ...' do
        expect(level5.path.length).to eq(1000)
        expect(level5.path[0..2]).to eq('...')
      end
    end
  end

  describe '#parent_folders' do
    let(:grandfather) { FactoryGirl.create(:document_folder) }
    let(:father) { FactoryGirl.create(:document_folder, folder_id: grandfather.id) }
    let(:son) { FactoryGirl.create(:document_folder, folder_id: father.id) }

    it 'returns an array of all ancestors' do
      expect(son.parent_folders).to eq([father, grandfather])
    end
  end

  describe '#all_group_ids' do
    let(:group1) { FactoryGirl.create(:group) }
    let(:group2) { FactoryGirl.create(:group) }
    let(:group3) { FactoryGirl.create(:group) }
    let(:grandfather) { FactoryGirl.create(:document_folder, group_ids: [group1.id]) }
    let(:father) { FactoryGirl.create(:document_folder, folder_id: grandfather.id, group_ids: [group1.id, group2.id]) }
    let(:son) { FactoryGirl.create(:document_folder, folder_id: father.id, group_ids: [group3.id]) }

    it 'returns an array of all group ids' do
      expect(son.all_group_ids).to match_array([group1.id, group2.id, group3.id])
    end
  end

  describe '#hidden_at_all?' do
    context 'grandfather is hidden' do
      let(:grandfather) { FactoryGirl.create(:document_folder, hidden: true) }
      let(:father) { FactoryGirl.create(:document_folder, folder_id: grandfather.id) }
      let(:son) { FactoryGirl.create(:document_folder, folder_id: father.id) }

      it 'returns true' do
        expect(son.hidden_at_all?).to eq(true)
      end
    end

    context 'self is hidden' do
      let(:grandfather) { FactoryGirl.create(:document_folder) }
      let(:father) { FactoryGirl.create(:document_folder, folder_id: grandfather.id) }
      let(:son) { FactoryGirl.create(:document_folder, folder_id: father.id, hidden: true) }

      it 'returns true' do
        expect(son.hidden_at_all?).to eq(true)
      end
    end

    context 'self is not hidden and no parent folders are hidden' do
      let(:grandfather) { FactoryGirl.create(:document_folder) }
      let(:father) { FactoryGirl.create(:document_folder, folder_id: grandfather.id) }
      let(:son) { FactoryGirl.create(:document_folder, folder_id: father.id) }

      it 'returns false' do
        expect(son.hidden_at_all?).to eq(false)
      end
    end
  end
end
