class CreateMessageMembersJoinTable < ActiveRecord::Migration
  def change
    create_join_table :messages, :members do |t|
      t.index [:message_id, :member_id]
      t.index [:member_id, :message_id]
    end
  end
end
