# == Schema Information
#
# Table name: publications
#
#  id          :integer       not null, primary key
#  name        :string(255)   
#  description :text          
#  created_at  :datetime      
#  file        :string(255)   
#  updated_at  :datetime      
#  site_id     :integer       
#

class Publication < ActiveRecord::Base
  belongs_to :site
  
  scope_by_site_id
  
  has_one_file :path => DB_PUBLICATIONS_PATH
  acts_as_logger LogItem
  
  validates_presence_of :name
  validates_uniqueness_of :name
  
  def pseudo_file_name
    filename = name.scan(/[a-z0-9]/i).join
    filename = id.to_s if filename.empty?
    filename + '.' + file_name.split('.').last
  end
end
