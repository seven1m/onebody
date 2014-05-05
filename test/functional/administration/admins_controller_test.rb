require_relative '../../test_helper'

class Administration::AdminsControllerTest < ActionController::TestCase

  setup do
    @admin = FactoryGirl.create(:person, :super_admin)
    @user = FactoryGirl.create(:person)
  end

  should 'add administrator' do
    post :create, { ids: [@user.id] }, { logged_in_id: @admin.id }
    assert_redirected_to administration_admins_path
    assert_equal I18n.t('admin.admin_added', name: @user.name) + ' ', flash[:notice]
    assert @user.reload.admin?
  end

  should 'remove administrator' do
    @user.update_attribute(:admin, Admin.create!)
    post :destroy, { id: @user.admin_id }, { logged_in_id: @admin.id }
    assert_redirected_to administration_admins_path
    assert_equal I18n.t('admin.admin_removed'), flash[:notice]
    assert !@user.reload.admin?
  end

end
