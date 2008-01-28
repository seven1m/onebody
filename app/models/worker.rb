# == Schema Information
# Schema version: 91
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
#  site_id     :integer       
#

class Worker < ActiveRecord::Base
  belongs_to :ministry
  belongs_to :person
  belongs_to :site
  
  acts_as_scoped_globally 'site_id', 'Site.current.id'
end
