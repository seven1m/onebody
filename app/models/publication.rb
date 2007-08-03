# == Schema Information
# Schema version: 74
#
# Table name: publications
#
#  id          :integer(11)   not null, primary key
#  name        :string(255)   
#  description :text          
#  created_at  :datetime      
#  file        :string(255)   
#  updated_at  :datetime      
#

class Publication < ActiveRecord::Base
  acts_as_file 'db/publications'
  acts_as_logger LogItem
  
  def pseudo_file_name
    filename = name.scan(/[a-z0-9]/i).join
    filename = id.to_s if filename.empty?
    filename + '.' + file_name.split('.').last
  end
end
