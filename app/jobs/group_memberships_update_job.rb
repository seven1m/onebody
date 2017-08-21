class GroupMembershipsUpdateJob < ApplicationJob
  queue_as :group_memberships_update

  def perform(site)
    ActiveRecord::Base.connection_pool.with_connection do
      Site.with_current(site) do
        Group.update_memberships
      end
    end
  end
end
