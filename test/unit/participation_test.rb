require File.dirname(__FILE__) + '/../test_helper'

class ParticipationTest < ActiveSupport::TestCase
  fixtures :people, :participation_categories

  def test_participation_creation
    assert_equal 0, people(:tim).participations.size
    assert_equal 0, people(:tim).participations.current.size
    assert_equal 0, people(:tim).participations.pending.size
    assert_equal 0, people(:tim).participations.historical.size

    people(:tim).participations.create :participation_category => participation_categories(:website), :status => "current"
    people(:tim).participations.create :participation_category => participation_categories(:choir), :status => "current"
    people(:tim).participations.create :participation_category => participation_categories(:sound_system), :status => "completed"
    people(:tim).participations.create :participation_category => participation_categories(:liturgist), :status => "pending"
    assert_equal 4, people(:tim).participations.size
    assert_equal 2, people(:tim).participations.current.size
    assert_equal 1, people(:tim).participations.historical.size
    assert_equal 1, people(:tim).participations.pending.size

    people(:mac).participations.create :participation_category => participation_categories(:website), :status => "current"
    assert_equal 1, people(:mac).participations.size
    assert_equal 1, people(:mac).participations.current.size
    assert_equal 0, people(:mac).participations.historical.size
    assert_equal 0, people(:mac).participations.pending.size

    people(:megan).participations.create :participation_category => participation_categories(:choir), :status => "current"
    assert_equal 1, people(:megan).participations.size
    assert_equal 1, people(:megan).participations.current.size
    assert_equal 0, people(:megan).participations.historical.size
    assert_equal 0, people(:megan).participations.pending.size

    people(:jennie).participations.create :participation_category => participation_categories(:choir), :status => "current"
    assert_equal 1, people(:jennie).participations.size
    assert_equal 1, people(:jennie).participations.current.size
    assert_equal 0, people(:jennie).participations.historical.size
    assert_equal 0, people(:jennie).participations.pending.size

    assert_equal 2, participation_categories(:website).people.size
    assert_equal 3, participation_categories(:choir).people.size
    assert_equal 1, participation_categories(:sound_system).people.size
    assert_equal 1, participation_categories(:liturgist).people.size
  end

end
