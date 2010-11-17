require File.dirname(__FILE__) + '/test_helper'

class ActsAsLoggerTest < ActiveSupport::TestCase

  test "log changes" do
    p = Person.new(:first_name => 'Tim', :last_name => 'Morgan', :age => 29, :admin => true)
    assert_nothing_thrown do
      p.save!
    end
    assert log_item = LogItem.find_by_loggable_type_and_loggable_id('Person', p.id, :order => 'id desc')
    assert_equal({
      'first_name' => [nil,   'Tim'   ],
      'last_name'  => [nil,   'Morgan'],
      'age'        => [nil,   29      ],
      'admin'      => [false, true    ]
    }, log_item.object_changes)
    assert_nothing_thrown do
      p.update_attributes!(:first_name => 'Timothy', :age => 30, :admin => false)
    end
    assert log_item = LogItem.find_by_loggable_type_and_loggable_id('Person', p.id, :order => 'id desc')
    assert_equal({
      'first_name' => ['Tim', 'Timothy'],
      'age'        => [29,    30       ],
      'admin'      => [true,  false    ]
    }, log_item.object_changes)
  end

end

class LogItem < ActiveRecord::Base
  belongs_to :loggable, :polymorphic => true
  belongs_to :person
  serialize :object_changes
end

class Person < ActiveRecord::Base
  cattr_accessor :logged_in
  acts_as_logger LogItem
end

ActiveRecord::Base.establish_connection :adapter => 'sqlite3', :database => ':memory:'

ActiveRecord::Schema.define do
  create_table "people", :force => true do |t|
    t.string   "first_name", "last_name"
    t.integer  "age"
    t.boolean  "admin", :default => false
  end
  create_table "log_items", :force => true do |t|
    t.string   "name"
    t.text     "object_changes"
    t.integer  "person_id"
    t.integer  "group_id"
    t.datetime "created_at"
    t.datetime "reviewed_on"
    t.integer  "reviewed_by"
    t.datetime "flagged_on"
    t.string   "flagged_by"
    t.boolean  "deleted",        :default => false
    t.integer  "loggable_id"
    t.string   "loggable_type"
  end
end

# not sure why this isn't automatic...
if $0 == __FILE__
  require 'test/unit/ui/console/testrunner'
  Test::Unit::UI::Console::TestRunner.run(ActsAsLoggerTest)
end

