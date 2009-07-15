class AddOriginalUrlToPictures < ActiveRecord::Migration
  def self.up
    change_table :pictures do |t|
      t.string :original_url, :limit => 1000
    end
  end

  def self.down
    change_table :pictures do |t|
      t.remove :original_url
    end
  end
end
