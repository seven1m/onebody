class LogItemsPolymorphic < ActiveRecord::Migration
  def self.up
    change_table :log_items do |t|
      t.references :loggable, :polymorphic => true
    end
    Site.each { LogItem.update_all("loggable_type = model_name, loggable_id = instance_id") }
    change_table :log_items do |t|
      t.remove :model_name
      t.remove :instance_id
    end
  end

  def self.down
    change_table :log_items do |t|
      t.string :model_name, :limit => 50
      t.integer :instance_id
    end
    Site.each { LogItem.update_all("model_name = loggable_type, instance_id = loggable_id") }
    change_table :log_items do |t|
      t.remove :loggable_type
      t.remove :loggable_id
    end
  end
end
