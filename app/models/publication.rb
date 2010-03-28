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
#  person_id   :integer       
#

class Publication < ActiveRecord::Base
  belongs_to :person
  belongs_to :site
  
  scope_by_site_id
  
  attr_accessible :name, :description
  
  has_one_file :path => DB_PUBLICATIONS_PATH
  acts_as_logger LogItem
  
  validates_presence_of :name
  validates_uniqueness_of :name
  
  def pseudo_file_name
    filename = name.scan(/[a-z0-9]/i).join
    filename = id.to_s if filename.empty?
    filename + '.' + file_name.split('.').last
  end
  
  after_create :create_as_stream_item
  
  def create_as_stream_item
    StreamItem.create!(
      :title           => name,
      :body            => description,
      :person_id       => person_id,
      :streamable_type => 'Publication',
      :streamable_id   => id,
      :created_at      => created_at
    )
  end
  
  after_destroy :delete_stream_items
  
  def delete_stream_items
    StreamItem.destroy_all(:streamable_type => 'Publication', :streamable_id => id)
  end
end
