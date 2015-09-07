class MakeEmailOnGroupsFalseByDefault < ActiveRecord::Migration
  def change
    change_column :groups, :email, :boolean, default: false
  end
end
