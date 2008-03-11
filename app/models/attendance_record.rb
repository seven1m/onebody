# == Schema Information
# Schema version: 4
#
# Table name: attendance_records
#
#  id          :integer       not null, primary key
#  person_id   :integer       
#  barcode_id  :string(50)    
#  first_name  :string(255)   
#  last_name   :string(255)   
#  family_name :string(255)   
#  age         :string(255)   
#  section     :string(255)   
#  in          :datetime      
#  out         :datetime      
#  void        :boolean       
#  created_at  :datetime      
#  updated_at  :datetime      
#

class AttendanceRecord < ActiveRecord::Base
  belongs_to :person
  
  class << self
    def check(person, section)
      today = Date.today
      if prev_record = person.attendance_records.find(:first, :conditions => ['section = ? and "in" >= ? and "in" < ? and out is null', section, today, today+1])
        prev_record.update_attribute :out, Time.now
        prev_record
      else
        person.attendance_records.create(:barcode_id => person.barcode_id, :first_name => person.first_name, :last_name => person.last_name, :family_name => person.family.name, :age => person.age[:years], :section => section, :in => Time.now) rescue nil
      end
    end
  end
end
