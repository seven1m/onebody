require File.dirname(__FILE__) + '/../test_helper'

class NoteTest < ActiveSupport::TestCase
  fixtures :notes

  def setup
    @person = Person.forge
    @note = Note.forge
  end

  should "only set group if user can post to group" do
    Person.logged_in = @person
    @group = Group.forge
    # user cannot post
    @note.group_id = @group.id
    assert @note.group.nil?
    assert @note.group_id.nil?
    # user can post
    @group.memberships.create! :person => @person
    # set by object
    @note.group = nil
    @note.group = @group
    assert_equal @group, @note.group
    assert_equal @group.id, @note.group_id
    # set by id
    @note.group = nil
    @note.group_id = @group.id
    assert_equal @group, @note.group
    assert_equal @group.id, @note.group_id
  end

end
