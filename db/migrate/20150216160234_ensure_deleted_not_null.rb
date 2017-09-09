class EnsureDeletedNotNull < ActiveRecord::Migration[4.2]
  def change
    Site.each do
      Family.where('deleted is null').update_all(deleted: false)
      Person.where('deleted is null').update_all(deleted: false)
    end

    change_column :people,   :deleted, :boolean, default: false, null: false
    change_column :families, :deleted, :boolean, default: false, null: false
  end
end
