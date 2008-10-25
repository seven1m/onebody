class ApprovalToJoinGroupOption < ActiveRecord::Migration
  def self.up
    change_table :groups do |t|
      t.boolean :approval_required_to_join, :default => true
    end
  end

  def self.down
    change_table :groups do |t|
      t.remove :approval_required_to_join
    end
  end
end
