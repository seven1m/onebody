class CreateVerifications < ActiveRecord::Migration
  def self.up
    create_table :verifications do |t|
      t.column :email, :strong, :limit => 255
      t.column :mobile_phone, :bigint
      t.column :code, :int
      t.column :verified, :boolean # nil = pending
      t.column :created_at, :datetime
    end
  end

  def self.down
    drop_table :verifications
  end
end
