class Publication < ActiveRecord::Base
  acts_as_file 'db/publications'
  
  def pseudo_file_name
    filename = name.scan(/[a-z0-9]/i).join
    filename = id.to_s if filename.empty?
    filename + '.' + file_name.split('.').last
  end
end
