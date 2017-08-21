class MessageSendJob < ApplicationJob
  queue_as :email

  def perform(site, message_id)
    ActiveRecord::Base.connection_pool.with_connection do
      Site.with_current(site) do
        Message.find(message_id).send_message
      end
    end
  end
end
