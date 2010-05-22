require File.dirname(__FILE__) + '/../test_helper'

class ImportTest < ActiveSupport::TestCase
  
  def setup
    @admin = Person.forge(:admin => Admin.create(:import_data => true, :edit_profiles => true))
    Person.logged_in = @admin
  end

  should "accept file data and queue changes for review from an admin with import_data privileges" do
    data = "first_name,last_name,child,member,sequence\n" +
           "Jean-Luc,Picard,false,true,1"
    changes = Person.queue_import_from_csv_file(data)
    assert_equal 1, changes.length
    assert_equal({"last_name" => [nil, "Picard"], "first_name" => [nil, "Jean-Luc"], "child" => [nil, false], "member" => [false, true], "sequence" => [nil, 1]},
                 changes.first[1])
  end

  should "import data" do
    @old_person = Person.forge('first_name' => 'Bill', 'last_name' => 'Riker', 'child' => true, 'sequence' => 3)
    data = "first_name,last_name,child,member,sequence\n" +
           "Jean-Luc,Picard,false,true,1"
    changes = Person.queue_import_from_csv_file(data)
    completed, errored = Person.import_data(
      :new     => {'0' => {'first_name' => 'Jean-Luc', 'last_name' => 'Picard', 'child' => 'false', 'member' => 'true', 'sequence' => '1'}},
      :changes => {@old_person.id => {'first_name' => 'William', 'child' => 'false', 'sequence' => '1'}}
    )
    assert_equal [], errored
    assert_equal 2, completed.length
    assert @new_person = Person.find_by_last_name('Picard')
    assert_equal ['Jean-Luc', 'Picard', false, true,  1], [@new_person.first_name, @new_person.last_name, @new_person.child?, @new_person.member?, @new_person.sequence]
    @old_person.reload
    assert_equal ['William',  'Riker',  false, false, 1], [@old_person.first_name, @old_person.last_name, @old_person.child?, @old_person.member?, @old_person.sequence]
  end

end
