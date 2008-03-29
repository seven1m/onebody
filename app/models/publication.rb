# == Schema Information
# Schema version: 4
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
  
  acts_as_scoped_globally 'site_id', "(Site.current ? Site.current.id : 'site-not-set')"
  
  acts_as_file DB_PUBLICATIONS_PATH
  acts_as_logger LogItem
  
  def pseudo_file_name
    filename = name.scan(/[a-z0-9]/i).join
    filename = id.to_s if filename.empty?
    filename + '.' + file_name.split('.').last
  end
end
