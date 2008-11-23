require File.dirname(__FILE__) + '/../test_helper'

class ServiceTest < ActiveSupport::TestCase
  fixtures :people, :service_categories

  def test_service_creation
    assert_equal 0, people(:tim).services.size
    assert_equal 0, people(:tim).services.current.size
    assert_equal 0, people(:tim).services.pending.size
    assert_equal 0, people(:tim).services.historical.size

    people(:tim).services.create :service_category => service_categories(:website), :status => "current"
    people(:tim).services.create :service_category => service_categories(:choir), :status => "current"
    people(:tim).services.create :service_category => service_categories(:sound_system), :status => "completed"
    people(:tim).services.create :service_category => service_categories(:liturgist), :status => "pending"
    assert_equal 4, people(:tim).services.size
    assert_equal 2, people(:tim).services.current.size
    assert_equal 1, people(:tim).services.historical.size
    assert_equal 1, people(:tim).services.pending.size

    people(:mac).services.create :service_category => service_categories(:website), :status => "current"
    assert_equal 1, people(:mac).services.size
    assert_equal 1, people(:mac).services.current.size
    assert_equal 0, people(:mac).services.historical.size
    assert_equal 0, people(:mac).services.pending.size

    people(:megan).services.create :service_category => service_categories(:choir), :status => "current"
    assert_equal 1, people(:megan).services.size
    assert_equal 1, people(:megan).services.current.size
    assert_equal 0, people(:megan).services.historical.size
    assert_equal 0, people(:megan).services.pending.size

    people(:jennie).services.create :service_category => service_categories(:choir), :status => "current"
    assert_equal 1, people(:jennie).services.size
    assert_equal 1, people(:jennie).services.current.size
    assert_equal 0, people(:jennie).services.historical.size
    assert_equal 0, people(:jennie).services.pending.size

    assert_equal 2, service_categories(:website).people.size
    assert_equal 3, service_categories(:choir).people.size
    assert_equal 1, service_categories(:sound_system).people.size
    assert_equal 1, service_categories(:liturgist).people.size
  end

end
