require_relative '../../test_helper'

class Administration::AdminsControllerTest < ActionController::TestCase

  should 'add administrator' do
    post :create, {:ids => [people(:jeremy).id]}, {:logged_in_id => people(:tim).id}
    assert_redirected_to administration_admins_path
    assert_equal I18n.t('admin.admin_added', :name => people(:jeremy).name) + ' ', flash[:notice]
    assert people(:jeremy).reload.admin?
  end

  should 'remove administrator' do
    people(:jeremy).update_attribute(:admin, Admin.create!)
    post :destroy, {:id => people(:jeremy).admin_id}, {:logged_in_id => people(:tim).id}
    assert_redirected_to administration_admins_path
    assert_equal I18n.t('admin.admin_removed'), flash[:notice]
    assert !people(:jeremy).reload.admin?
  end

end
