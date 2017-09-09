class AddPrimaryEmailerToPeople < ActiveRecord::Migration[4.2]
  def change
    change_table :people do |t|
      t.boolean :primary_emailer
    end
  end
end
