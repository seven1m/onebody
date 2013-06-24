class Job < ActiveRecord::Base

  has_many :generated_files
  scope_by_site_id

  def self.add(command)
    create!(command: command)
  end

end
