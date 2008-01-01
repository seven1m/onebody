# == Schema Information
# Schema version: 89
#
# Table name: ministries
#
#  id          :integer       not null, primary key
#  admin_id    :integer       
#  name        :string(100)   
#  description :text          
#  updated_at  :datetime      
#

class Ministry < ActiveRecord::Base
  belongs_to :administrator, :class_name => 'Person', :foreign_key => 'admin_id'
  has_many :workers, :dependent => :destroy
  has_many :people, :through => :workers, :conditions => ['workers.start >= ?', Date.today-120], :order => 'last_name, first_name'
  
  validates_presence_of :name
  validates_uniqueness_of :name
  validates_presence_of :admin_id
  
  acts_as_logger LogItem
  
  def dates
    dates = workers.find_by_sql "select #{sql_month('start')} as m, #{sql_day('start')} as d, #{sql_year('start')} as y, id from workers where ministry_id = #{self.id}"
    dates_hash = {}
    dates.each do |date|
      d = Date.new(date.y.to_i, date.m.to_i, date.d.to_i)
      dates_hash[d] ||= []
      dates_hash[d] << Worker.find(date.id)
    end
    dates_hash.each do |date, workers|
      dates_hash[date] = dates_hash[date].sort_by { |w| [w.person.last_name, w.person.first_name] }
    end
    dates_hash.to_a.sort_by { |d| d.first }
  end
  
  class << self
    def send_reminders # should be called once per day by a cron script
      today = Date.today
      Worker.find_all_by_remind_on_and_reminded(today, false).each do |worker|
        Notifier.deliver_service_reminder(worker)
      end
    end
  end
end
