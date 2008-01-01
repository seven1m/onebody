# == Schema Information
# Schema version: 89
#
# Table name: workers
#
#  id          :integer       not null, primary key
#  ministry_id :integer       
#  person_id   :integer       
#  start       :datetime      
#  end         :datetime      
#  remind_on   :datetime      
#  reminded    :boolean       
#

class Worker < ActiveRecord::Base
  belongs_to :ministry
  belongs_to :person
end
