require_relative '../../rails_helper'

describe Administration::AdminsController, type: :controller do
  before do
    @admin = FactoryGirl.create(:person, :super_admin)
    @user = FactoryGirl.create(:person)
  end

  it 'should add administrator' do
    post :create, { ids: [@user.id] }, logged_in_id: @admin.id
    expect(response).to redirect_to(administration_admins_path)
    expect(flash[:notice]).to eq(I18n.t('admin.admin_added', name: @user.name) + ' ')
    expect(@user.reload).to be_admin
  end

  it 'should remove administrator' do
    @user.update_attribute(:admin, Admin.create!)
    post :destroy, { id: @user.admin_id }, logged_in_id: @admin.id
    expect(response).to redirect_to(administration_admins_path)
    expect(flash[:notice]).to eq(I18n.t('admin.admin_removed'))
    expect(@user.reload).to_not be_admin
  end
end
