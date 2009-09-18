# == Schema Information
#
# Table name: verifications
#
#  id           :integer       not null, primary key
#  verified     :boolean       
#  created_at   :datetime      
#  email        :string(255)   
#  code         :integer       
#  mobile_phone :string(25)    
#  updated_at   :datetime      
#  site_id      :integer       
#

class Verification < ActiveRecord::Base
  belongs_to :site
  
  scope_by_site_id

  # generates security code
  def before_create
    conditions = ['created_at >= ? and email = ?', Date.today, email]
    if Verification.count('*', :conditions => conditions) >= MAX_DAILY_VERIFICATION_ATTEMPTS
      errors.add_to_base 'You have exceeded the daily limit for verification attempts.'
      return false
    else
      begin
        code = rand(999999)
        write_attribute :code, code
      end until code > 0
    end
  end
  
  def pending?
    read_attribute(:verified).nil?
  end
end
