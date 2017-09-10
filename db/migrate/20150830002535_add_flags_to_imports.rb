class AddFlagsToImports < ActiveRecord::Migration[4.2]
  def change
    change_table :imports do |t|
      t.integer :flags, null: false, default: 0
    end
  end
end
