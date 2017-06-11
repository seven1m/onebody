require_relative '../../rails_helper'

describe PersonAuthorizer do
  before do
    @user = FactoryGirl.create(:person)
  end

  context 'user has account frozen' do
    before do
      @user.update_attributes!(account_frozen: true)
    end

    it 'should read self' do
      expect(@user).to be_able_to(:read, @user)
    end

    it 'should not update self' do
      expect(@user).to_not be_able_to(:update, @user)
    end
  end

  context 'given a stranger' do
    before do
      @stranger = FactoryGirl.create(:person)
    end

    it 'should read stranger' do
      expect(@user).to be_able_to(:read, @stranger)
    end

    it 'should not update a stranger' do
      expect(@user).to_not be_able_to(:update, @stranger)
    end

    context 'stranger is deleted' do
      before do
        @stranger.update_attributes!(deleted: true)
      end

      it 'should not read stranger' do
        expect(@user).to_not be_able_to(:read, @stranger)
      end
    end

    context 'stranger is not visible' do
      before do
        @stranger.update_attributes!(visible: false)
      end

      it 'should not read stranger' do
        expect(@user).to_not be_able_to(:read, @stranger)
      end
    end

    context 'stranger is inactive' do
      before do
        @stranger.update_attributes!(status: :inactive)
      end

      it 'should not read stranger' do
        expect(@user).to_not be_able_to(:read, @stranger)
      end
    end

    context 'stranger family is not visible' do
      before do
        @stranger.family.update_attributes!(visible: false)
      end

      it 'should not read stranger' do
        expect(@user).to_not be_able_to(:read, @stranger)
      end
    end

    context 'stranger is a child' do
      before do
        @stranger.update_attributes!(child: true)
      end

      it 'should not read stranger' do
        expect(@user).to_not be_able_to(:read, @stranger)
      end

      context 'child has parental consent' do
        before do
          @stranger.update_attributes!(parental_consent: true)
        end

        it 'should read stranger' do
          expect(@user).to be_able_to(:read, @stranger)
        end
      end

      context 'user is admin with view_hidden_profiles privilege' do
        before do
          @user.update_attributes!(admin: Admin.create!(view_hidden_profiles: true))
        end

        it 'should read stranger' do
          expect(@user).to be_able_to(:read, @stranger)
        end
      end
    end
  end

  it 'should read self' do
    expect(@user).to be_able_to(:read, @user)
  end

  it 'should update self' do
    expect(@user).to be_able_to(:update, @user)
  end

  context 'self is deleted' do
    before do
      @user.update_attributes!(deleted: true)
    end

    it 'should not read self' do
      expect(@user).to_not be_able_to(:read, @user)
    end
  end

  context 'family is deleted' do
    before do
      @user.family.update_attributes!(deleted: true)
    end

    it 'should not read self' do
      expect(@user).to_not be_able_to(:read, @user)
    end
  end

  context 'given another adult in the same family' do
    before do
      @adult = FactoryGirl.create(:person, family: @user.family, child: false)
    end

    it 'should read adult' do
      expect(@user).to be_able_to(:read, @adult)
    end

    it 'should update adult' do
      expect(@user).to be_able_to(:update, @adult)
    end

    context 'user is not an adult' do
      before do
        @user.update_attributes!(child: true)
      end

      it 'should not update adult' do
        expect(@user).to_not be_able_to(:update, @adult)
      end
    end
  end

  context 'given a child in the same family' do
    before do
      @child = FactoryGirl.create(:person, family: @user.family, child: true)
    end

    it 'should read child' do
      expect(@user).to be_able_to(:read, @child)
    end

    it 'should update child' do
      expect(@user).to be_able_to(:update, @child)
    end

    context 'user is not an adult' do
      before do
        @user.update_attributes!(child: true)
      end

      it 'should not update child' do
        expect(@user).to_not be_able_to(:update, @child)
      end
    end
  end

  context 'given a deleted person in the same family' do
    before do
      @deleted = FactoryGirl.create(:person, family: @user.family, deleted: true)
    end

    it 'should not update deleted person' do
      expect(@user).to_not be_able_to(:update, @deleted)
    end
  end

  context 'user is admin with edit_profiles privilege' do
    before do
      @user.update_attributes!(admin: Admin.create!(edit_profiles: true))
    end

    it 'should create new person' do
      expect(@user).to be_able_to(:create, Person)
    end

    context 'given a stranger' do
      before do
        @stranger = FactoryGirl.create(:person)
      end

      it 'should update stranger' do
        expect(@user).to be_able_to(:update, @stranger)
      end

      it 'should delete stranger' do
        expect(@user).to be_able_to(:delete, @stranger)
      end

      context 'stranger is deleted' do
        before do
          @stranger.update_attributes!(deleted: true)
        end

        it 'should update stranger' do
          expect(@user).to be_able_to(:update, @stranger)
        end
      end

      context 'stranger is hidden' do
        before do
          @stranger.update_attributes!(visible: false)
        end

        it 'should not read stranger' do
          expect(@user).to_not be_able_to(:read, @stranger)
        end

        it 'should not update stranger' do
          expect(@user).to_not be_able_to(:update, @stranger)
        end

        it 'should not delete stranger' do
          expect(@user).to_not be_able_to(:delete, @stranger)
        end

        context 'admin also has view_hidden_profiles privilege' do
          before do
            @user.admin.update_attributes!(view_hidden_profiles: true)
          end

          it 'should read stranger' do
            expect(@user).to be_able_to(:read, @stranger)
          end

          it 'should update stranger' do
            expect(@user).to be_able_to(:update, @stranger)
          end

          it 'should delete stranger' do
            expect(@user).to be_able_to(:delete, @stranger)
          end
        end
      end
    end
  end

  it 'should not delete self' do
    expect(@user).to_not be_able_to(:delete, @user)
  end

  it 'should not delete spouse' do
    @spouse = FactoryGirl.create(:person, family: @user.family, child: false)
    expect(@user).to_not be_able_to(:delete, @spouse)
  end

  it 'should not create new person' do
    expect(@user).to_not be_able_to(:create, Person)
  end
end
