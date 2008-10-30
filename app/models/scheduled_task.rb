# == Schema Information
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
  
  def system_command
    c = command.dup
    c.gsub!(/TASK_BASE_FILE_PATH/, base_file_path)
    if self.site
      c.gsub!(/SITE_NAME/,      site.name || '')
      c.gsub!(/EMAIL_HOST/,     Setting.find_by_section_and_name_and_global('Email', 'Host', true).value || '')
      c.gsub!(/EMAIL_USERNAME/, site.settings.find_by_section_and_name('Email', 'Username'  ).value || '')
      c.gsub!(/EMAIL_PASSWORD/, site.settings.find_by_section_and_name('Email', 'Password'  ).value || '')
    end
    return c
  end
  
  def self.queue(name, command, runner=true)
    Site.current.scheduled_tasks.create!(
      :name     => name,
      :command  => command,
      :interval => 'now',
      :runner   => runner
    )
  end
end
