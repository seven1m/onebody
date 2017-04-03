class AddEventIdToVerifications < ActiveRecord::Migration
  def change
    add_reference :verifications, :event
  end
end
