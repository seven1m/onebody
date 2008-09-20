class FixZeroDates < ActiveRecord::Migration
  def self.up
    Person.connection.execute("update people set anniversary = NULL where #{sql_year('anniversary')} < 1000")
    Person.connection.execute("update people set birthday    = NULL where #{sql_year('birthday')}    < 1000")
  end

  def self.down
  end
end
