# == Schema Information
#
# Table name: signin_failures
#
#  id         :integer       not null, primary key
#  email      :string(255)   
#  ip         :string(255)   
#  created_at :datetime      
#

class SigninFailure < ActiveRecord::Base
end
