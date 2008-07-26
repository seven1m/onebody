# == Schema Information
# Schema version: 20080724143144
#
# Table name: scheduled_tasks
#
#  id         :integer       not null, primary key
#  name       :string(100)   
#  command    :text          
#  interval   :string(255)   
#  active     :boolean       default(TRUE)
#  runner     :boolean       default(TRUE)
#  site_id    :integer       
#  created_at :datetime      
#  updated_at :datetime      
#

class ScheduledTask < ActiveRecord::Base
  belongs_to :site
  validates_presence_of :name, :command
  
  acts_as_file DB_TASK_FILES_PATH
  
  def self.queue(name, command, runner=true)
    Site.current.scheduled_tasks.create!(
      :name     => name,
      :command  => command,
      :interval => 'now',
      :runner   => runner
    )
  end
end
