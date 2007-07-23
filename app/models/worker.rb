# == Schema Information
# Schema version: 65
#
# Table name: workers
#
#  id          :integer(11)   not null, primary key
#  ministry_id :integer(11)   
#  person_id   :integer(11)   
#  start       :datetime      
#  end         :datetime      
#  remind_on   :datetime      
#  reminded    :boolean(1)    
#

# == Schema Information
# Schema version: 64
#
# Table name: workers
#
#  id          :integer(11)   not null, primary key
#  ministry_id :integer(11)   
#  person_id   :integer(11)   
#  start       :datetime      
#  end         :datetime      
#  remind_on   :datetime      
#  reminded    :boolean(1)    
#

class Worker < ActiveRecord::Base
  belongs_to :ministry
  belongs_to :person
end
