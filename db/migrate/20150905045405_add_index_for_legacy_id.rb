class AddIndexForLegacyId < ActiveRecord::Migration[4.2]
  def change
    add_index :people, :legacy_id
    add_index :families, :legacy_id
  end
end
