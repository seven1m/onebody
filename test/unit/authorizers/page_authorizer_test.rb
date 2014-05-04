require_relative '../../test_helper'

class PageAuthorizerTest < ActiveSupport::TestCase

  setup do
    @user = FactoryGirl.create(:person)
    @page = FactoryGirl.create(:page)
  end


  should 'not update page' do
    assert_cannot @user, :update, @page
  end

  should 'not delete page' do
    assert_cannot @user, :delete, @page
  end

  context 'user is admin with edit_pages privilege' do
    setup do
      @user.update_attributes!(admin: Admin.create!(edit_pages: true))
    end

    should 'update page' do
      assert_can @user, :update, @page
    end

    should 'delete page' do
      assert_can @user, :delete, @page
    end
  end

end
