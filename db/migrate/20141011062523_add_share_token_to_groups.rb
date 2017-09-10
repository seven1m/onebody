class AddShareTokenToGroups < ActiveRecord::Migration[4.2]
  def change
    change_table :groups do |t|
      t.string :share_token, limit: 50

      Group.reset_column_information

      Site.each do
        Group.all.each do |group|
          group.set_share_token
          group.save(validate: false)
        end
      end
    end
  end
end
