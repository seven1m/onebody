class Publication < ActiveRecord::Base
  acts_as_file 'db/publications'
  acts_as_logger LogItem
  paranoid_attributes :name, :description
  
  def pseudo_file_name
    filename = name.scan(/[a-z0-9]/i).join
    filename = id.to_s if filename.empty?
    filename + '.' + file_name.split('.').last
  end
end
