class MessageSendJob < ActiveJob::Base
  queue_as :email

  def perform(message)
    ActiveRecord::Base.connection_pool.with_connection do
      message.send_message
    end
  end
end
