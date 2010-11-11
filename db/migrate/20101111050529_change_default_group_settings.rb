class ChangeDefaultGroupSettings < ActiveRecord::Migration
  def self.up
    change_column_default :groups, :approval_required_to_join, false
  end

  def self.down
    change_column_default :groups, :approval_required_to_join, true
  end
end
