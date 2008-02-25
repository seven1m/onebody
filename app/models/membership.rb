# == Schema Information
# Schema version: 1
#
# Table name: memberships
#
#  id                 :integer       not null, primary key
#  group_id           :integer       
#  person_id          :integer       
#  admin              :boolean       
#  get_email          :boolean       default(TRUE)
#  share_address      :boolean       
#  share_mobile_phone :boolean       
#  share_work_phone   :boolean       
#  share_fax          :boolean       
#  share_email        :boolean       
#  share_birthday     :boolean       
#  share_anniversary  :boolean       
#  updated_at         :datetime      
#  code               :integer       
#  site_id            :integer       
#

class Membership < ActiveRecord::Base
  belongs_to :group
  belongs_to :person
  belongs_to :site
  
  acts_as_scoped_globally 'site_id', 'Site.current.id'
  
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
