class Relationship < ActiveRecord::Base
  
  belongs_to :person
  belongs_to :related, :foreign_key => 'related_id', :class_name => 'Person'
  
  scope_by_site_id
  
  validates_presence_of :name
  validates_inclusion_of :name, :in => I18n.t(:relationships).keys.map { |r| r.to_s }
  validates_presence_of :other_name, :if => Proc.new { |r| r.name == 'other' }
  validates_presence_of :person_id
  validates_presence_of :related_id
  validates_uniqueness_of :related_id, :scope => [:person_id, :name]
  
  acts_as_logger LogItem
  
  def name_or_other
    name == 'other' ? other_name : I18n.t(name, :scope => 'relationships')
  end
  
end
