# == Schema Information
#
# Table name: notes
#
#  id           :integer       not null, primary key
#  person_id    :integer       
#  title        :string(255)   
#  body         :text          
#  created_at   :datetime      
#  updated_at   :datetime      
#  original_url :string(255)   
#  deleted      :boolean       
#  group_id     :integer       
#  site_id      :integer       
#

class Note < ActiveRecord::Base
  belongs_to :person
  belongs_to :group
  has_many :comments, :dependent => :destroy
  belongs_to :site
  
  scope_by_site_id
  
  acts_as_logger LogItem
  
  #validates_presence_of :title
  validates_presence_of :body
  
  def name; title; end
  
  def title=(t)
    write_attribute(:title, t.to_s.any? ? t : nil)
  end
  
  def group_id=(id)
    if group = Group.find_by_id(id) and group.can_post?(Person.logged_in)
      write_attribute :group_id, id
    else
      write_attribute :group_id, nil
    end
  end

  after_create :create_as_stream_item
  
  def create_as_stream_item
    return unless person
    StreamItem.create!(
      :title           => title,
      :body            => body,
      :context         => original_url.to_s.any? ? {'original_url' => original_url} : {},
      :person_id       => person_id,
      :group_id        => group_id,
      :streamable_type => 'Note',
      :streamable_id   => id,
      :created_at      => created_at,
      :shared          => group_id || person.share_activity? ? true : false
    )
  end
  
  after_update :update_stream_items
  
  def update_stream_items
    StreamItem.find_all_by_streamable_type_and_streamable_id('Note', id).each do |stream_item|
      stream_item.title = title
      stream_item.body  = body
      stream_item.save
    end
  end
  
  after_destroy :delete_stream_items
  
  def delete_stream_items
    StreamItem.destroy_all(:streamable_type => 'Note', :streamable_id => id)
  end
  
end
