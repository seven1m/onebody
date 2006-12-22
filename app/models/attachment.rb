class Attachment < ActiveRecord::Base
  belongs_to :message
  belongs_to :song
end
