class RemoveOldColumns < ActiveRecord::Migration[4.2]
  def up
    change_table :people do |t|
      t.remove :activities, :interests, :music, :tv_shows, :movies, :books, :quotes
    end
  end

  def down
    change_table :people do |t|
      t.text :activities, :interests, :music, :tv_shows, :movies, :books, :quotes
    end
  end
end
