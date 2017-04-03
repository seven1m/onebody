class CreateDiscountRules < ActiveRecord::Migration
  def change
    create_table :discount_rules do |t|
      t.belongs_to :site, index: true
      t.belongs_to :event, index: true
      t.string :name
      t.string :kind
      t.belongs_to :if_registrant_type, index: true
      t.belongs_to :then_registrant_type, index: true
      t.decimal :discount_fixed
      t.float :discount_percent

      t.timestamps null: false
    end
  end
end
