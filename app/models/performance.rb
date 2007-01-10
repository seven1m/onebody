class Performance < ActiveRecord::Base
  belongs_to :song
  belongs_to :setlist
  
  acts_as_logger LogItem
end
