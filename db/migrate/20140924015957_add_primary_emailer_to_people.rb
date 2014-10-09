class AddPrimaryEmailerToPeople < ActiveRecord::Migration
  def change
    change_table :people do |t|
      t.boolean :primary_emailer
    end
  end
end
