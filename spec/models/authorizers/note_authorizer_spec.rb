require_relative '../../spec_helper'

describe NoteAuthorizer do

  before do
    @user = FactoryGirl.create(:person)
    @note = FactoryGirl.create(:note)
  end

  it 'should read note' do
    expect(@user).to be_able_to(:read, @note)
  end

  it 'should not create note' do
    expect(@user).to_not be_able_to(:create, @note)
  end

  it 'should not update note' do
    expect(@user).to_not be_able_to(:update, @note)
  end

  it 'should not delete note' do
    expect(@user).to_not be_able_to(:delete, @note)
  end

  context 'owned by user' do
    before do
      @note.update_attributes!(person: @user)
    end

    it 'should create note' do
      expect(@user).to be_able_to(:create, @note)
    end

    it 'should update note' do
      expect(@user).to be_able_to(:update, @note)
    end

    it 'should delete note' do
      expect(@user).to be_able_to(:delete, @note)
    end
  end

  context 'user is admin with manage_notes privilege' do
    before do
      @user.update_attributes!(admin: Admin.create!(manage_notes: true))
    end

    it 'should create note' do
      expect(@user).to be_able_to(:create, @note)
    end

    it 'should update note' do
      expect(@user).to be_able_to(:update, @note)
    end

    it 'should delete note' do
      expect(@user).to be_able_to(:delete, @note)
    end
  end

  context 'note is in a group' do
    before do
      @group = FactoryGirl.create(:group)
      @note.update_attributes!(group: @group)
    end

    it 'should see note' do
      expect(@user).to be_able_to(:read, @note)
    end

    it 'should not create note' do
      expect(@user).to_not be_able_to(:create, @note)
    end

    context 'group is hidden' do
      before do
        @group.update_attributes!(hidden: true)
      end

      it 'should not see note' do
        expect(@user).to_not be_able_to(:read, @note)
      end

      it 'should not create note' do
        expect(@user).to_not be_able_to(:create, @note)
      end

      context 'user is a group member' do
        before do
          @group.memberships.create!(person: @user)
        end

        it 'should read note' do
          expect(@user).to be_able_to(:read, @note)
        end

        it 'should create note' do
          expect(@user).to be_able_to(:create, @note)
        end
      end
    end

    context 'group is private' do
      before do
        @group.update_attributes!(private: true)
      end

      it 'should not see note' do
        expect(@user).to_not be_able_to(:read, @note)
      end

      it 'should not create note' do
        expect(@user).to_not be_able_to(:create, @note)
      end

      context 'user is a group member' do
        before do
          @group.memberships.create!(person: @user)
        end

        it 'should read note' do
          expect(@user).to be_able_to(:read, @note)
        end

        it 'should create note' do
          expect(@user).to be_able_to(:create, @note)
        end
      end
    end
  end

  context 'note is owned by an invisible person' do
    before do
      @note.person.update_attributes!(visible: false)
    end

    it 'should not read note' do
      expect(@user).to_not be_able_to(:read, @note)
    end

    context 'note is in a group' do
      before do
        @group = FactoryGirl.create(:group)
        @note.update_attributes!(group: @group)
      end

      it 'should read note' do
        expect(@user).to be_able_to(:read, @note)
      end

      it 'should not update note' do
        expect(@user).to_not be_able_to(:update, @note)
      end

      context 'group is hidden' do
        before do
          @group.update_attributes!(hidden: true)
        end

        it 'should not read note' do
          expect(@user).to_not be_able_to(:read, @note)
        end

        context 'user is a group member' do
          before do
            @group.memberships.create!(person: @user)
          end

          it 'should read note' do
            expect(@user).to be_able_to(:read, @note)
          end
        end
      end
    end
  end

end
