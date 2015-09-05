class AddIndexForLegacyId < ActiveRecord::Migration
  def change
    add_index :people, :legacy_id
    add_index :families, :legacy_id
  end
end
