# == Schema Information
#
# Table name: syncs
#
#  id            :integer       not null, primary key
#  site_id       :integer       
#  person_id     :integer       
#  complete      :boolean       
#  success_count :integer       
#  error_count   :integer       
#  created_at    :datetime      
#  updated_at    :datetime      
#  started_at    :datetime      
#  finished_at   :datetime      
#

class Sync < ActiveRecord::Base
  belongs_to :site
  scope_by_site_id
  
  attr_accessible :complete, :success_count, :error_count, :started_at, :finished_at

  belongs_to :person
  has_many :sync_items, :dependent => :delete_all
  has_many :people,   :through => :sync_items, :source => :syncable, :source_type => 'Person'
  has_many :families, :through => :sync_items, :source => :syncable, :source_type => 'Family'
  has_many :groups,   :through => :sync_items, :source => :syncable, :source_type => 'Group'
  
  def total_count
    success_count.to_i + error_count.to_i
  end
  
  def success_rate
    if !complete?
      nil
    elsif total_count > 0
      success_count.to_i / total_count.to_f * 100.0
    else
      100.0
    end
  end
  
  def count_items
    {
      :create => sync_items.count('id', :conditions => {:operation => 'create'}),
      :update => sync_items.count('id', :conditions => {:operation => 'update'}),
      :error  => sync_items.count('id', :conditions => "status in ('error', 'saved with error')"),
    }.reject { |k, v| v == 0 }
  end
end
