class AddPrintExtraNametagToGroupTimes < ActiveRecord::Migration
  def change
    change_table :group_times do |t|
      t.boolean :print_extra_nametag, default: false
    end
  end
end
