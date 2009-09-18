# == Schema Information
#
# Table name: memberships
#
#  id                 :integer       not null, primary key
#  group_id           :integer       
#  person_id          :integer       
#  admin              :boolean       
#  share_address      :boolean       
#  share_mobile_phone :boolean       
#  share_work_phone   :boolean       
#  share_fax          :boolean       
#  share_email        :boolean       
#  share_birthday     :boolean       
#  share_anniversary  :boolean       
#  get_email          :boolean       default(TRUE)
#  updated_at         :datetime      
#  code               :integer       
#  site_id            :integer       
#  legacy_id          :integer       
#  share_home_phone   :boolean       
#  auto               :boolean       
#

class Membership < ActiveRecord::Base
  belongs_to :group
  belongs_to :person
  belongs_to :site
  
  validates_uniqueness_of :group_id, :scope => :person_id
  
  scope_by_site_id
  
  acts_as_logger LogItem
  
  def family; person.family; end
  
  # generates security code
  def before_create
    begin
      code = rand(999999)
      write_attribute :code, code
    end until code > 0
  end
  
  def self.sharing_columns
    columns.map { |c| c.name }.select { |c| c =~ /^share_/ }
  end
end
