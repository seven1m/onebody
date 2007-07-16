# == Schema Information
# Schema version: 63
#
# Table name: verifications
#
#  id           :integer(11)   not null, primary key
#  email        :string(255)   
#  mobile_phone :integer(20)   
#  code         :integer(11)   
#  verified     :boolean(1)    
#  created_at   :datetime      
#  updated_at   :datetime      
#

class Verification < ActiveRecord::Base

  # generates security code
  def before_create
    conditions = ['created_at >= ? and email = ?', Date.today, email]
    if Verification.count(:conditions => conditions) >= MAX_DAILY_VERIFICATION_ATTEMPTS
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
