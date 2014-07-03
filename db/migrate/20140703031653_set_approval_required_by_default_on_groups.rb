class SetApprovalRequiredByDefaultOnGroups < ActiveRecord::Migration
  def change
    change_column :groups, :approval_required_to_join, :boolean, default: true
  end
end
