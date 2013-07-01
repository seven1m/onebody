require_relative '../../test_helper'

class Administration::UpdatesControllerTest < ActionController::TestCase

  def setup
    @person = FactoryGirl.create(:person)
    @admin = FactoryGirl.create(:person, :admin_manage_updates)
  end

  context '#index' do
    context 'unauthorized user' do
      should 'return unauthorized' do
        get :index, nil, {logged_in_id: @person.id}
        assert_response 401
      end
    end

    context 'admin user' do
      setup do
        @update = @person.updates.create!(
          data: {
            person: {
              birthday: Date.new(2000, 1, 1)
            }
          }
        )
        @update_complete = @person.updates.create!(complete: true)
        get :index, nil, {logged_in_id: @admin.id}
      end

      should 'render the index template' do
        assert_template :index
      end

      should 'show pending updates' do
        assert_equal [@update], assigns[:updates]
      end

      should 'show dates formatted' do
        assert_match %r(<td>01/01/2000</td>), response.body
      end
    end
  end

  context '#update' do
    setup do
      @update = @person.updates.create!(
        data: {
          person: {
            first_name: 'Tim',
            last_name: 'Morgan'
          },
          family: {
            name: 'Tim Morgan'
          }
        },
        complete: false
      )
    end

    should 'mark the update complete' do
      put :update, {id: @update.id, update: {complete: 'true'}},
        {logged_in_id: @admin.id}
      assert @update.reload.complete
    end

    should 'mark the update incomplete' do
      @update.update_attribute(:complete, true)
      put :update, {id: @update.id, update: {complete: 'false'}},
        {logged_in_id: @admin.id}
      assert !@update.reload.complete
    end

    should 'apply the update' do
      put :update, {id: @update.id, update: {apply: 'true'}},
        {logged_in_id: @admin.id}
      assert @update.reload.complete?
      assert_equal 'Tim', @person.reload.first_name
    end
  end

  context '#destroy' do
    setup do
      @update = @person.updates.create!
    end

    should 'destroy the update' do
      delete :destroy, {id: @update.id}, {logged_in_id: @admin.id}
      assert_raise ActiveRecord::RecordNotFound do
        @update.reload
      end
    end
  end

end
