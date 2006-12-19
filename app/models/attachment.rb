class Attachment < ActiveRecord::Base
  belongs_to :message
end
