class AddNameToVerification < ActiveRecord::Migration
  def change
    add_column :verifications, :name, :string
  end
end
