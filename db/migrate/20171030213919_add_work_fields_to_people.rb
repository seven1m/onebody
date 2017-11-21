class AddWorkFieldsToPeople < ActiveRecord::Migration[5.1]
  def self.up
    add_column :people, :employer, :text
    add_column :people, :job_title, :text
  end

  def self.down
    remove_column :people, :employer
    remove_column :people, :job_title
  end
end