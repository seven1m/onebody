class CreateSyncInfo < ActiveRecord::Migration
  def self.up
    create_table :sync_info, :id => false do |t|
      t.column :last_update, :datetime
    end
  end

  def self.down
    drop_table :sync_info
  end
end
