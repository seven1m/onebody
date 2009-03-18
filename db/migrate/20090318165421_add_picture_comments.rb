class AddPictureComments < ActiveRecord::Migration
  def self.up
    add_column :comments, :picture_id, :integer
	Setting.update_all
	end
  end

  def self.down
    Setting.find(:all, :conditions => "name = 'Allow Picture Comments'").each { |s| s.destroy }
	remove_column :comments, :picture_id	
  end
end