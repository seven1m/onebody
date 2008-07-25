class ScheduledTask < ActiveRecord::Base
  belongs_to :site
  validates_presence_of :name, :command
  
  def self.queue(name, command, runner=true)
    Site.current.scheduled_tasks.create!(
      :name     => name,
      :command  => command,
      :interval => 'now',
      :runner   => runner
    )
  end
end
