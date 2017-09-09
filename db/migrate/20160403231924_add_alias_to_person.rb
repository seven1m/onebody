class AddAliasToPerson < ActiveRecord::Migration[4.2]
  def change
    add_column :people, :alias, :string
  end
end
