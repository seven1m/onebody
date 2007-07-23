# == Schema Information
# Schema version: 66
#
# Table name: memberships
#
#  id                 :integer(11)   not null, primary key
#  group_id           :integer(11)   
#  person_id          :integer(11)   
#  admin              :boolean(1)    
#  get_email          :boolean(1)    default(TRUE)
#  share_address      :boolean(1)    
#  share_mobile_phone :boolean(1)    
#  share_work_phone   :boolean(1)    
#  share_fax          :boolean(1)    
#  share_email        :boolean(1)    
#  share_birthday     :boolean(1)    
#  share_anniversary  :boolean(1)    
#  updated_at         :datetime      
#  code               :integer(11)   
#

# == Schema Information
# Schema version: 64
#
# Table name: memberships
#
#  id                 :integer(11)   not null, primary key
#  group_id           :integer(11)   
#  person_id          :integer(11)   
#  admin              :boolean(1)    
#  get_email          :boolean(1)    default(TRUE)
#  share_address      :boolean(1)    
#  share_mobile_phone :boolean(1)    
#  share_work_phone   :boolean(1)    
#  share_fax          :boolean(1)    
#  share_email        :boolean(1)    
#  share_birthday     :boolean(1)    
#  share_anniversary  :boolean(1)    
#  updated_at         :datetime      
#  code               :integer(11)   
#

class Membership < ActiveRecord::Base
  belongs_to :group
  belongs_to :person
  
  acts_as_logger LogItem
  
  def family; person.family; end
  
  inherited_attribute :share_address, :person
  inherited_attribute :share_mobile_phone, :person
  inherited_attribute :share_work_phone, :person
  inherited_attribute :share_fax, :person
  inherited_attribute :share_email, :person
  inherited_attribute :share_birthday, :person
  inherited_attribute :share_anniversary, :person
  
  # generates security code
  def before_create
    begin
      code = rand(999999)
      write_attribute :code, code
    end until code > 0
  end
end
