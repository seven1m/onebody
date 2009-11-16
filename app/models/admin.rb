# == Schema Information
#
# Table name: admins
#
#  id            :integer       not null, primary key
#  created_at    :datetime      
#  updated_at    :datetime      
#  site_id       :integer       
#  template_name :string(100)   
#  flags         :text          
#

class Admin < ActiveRecord::Base
  has_many :people
  def person; people.first; end # only admin templates have more than one
  
  belongs_to :site
  
  scope_by_site_id
  
  serialize :flags
  
  before_save :ensure_flags_is_hash
  
  def ensure_flags_is_hash
    self.flags = {} if not flags.is_a?(Hash)
  end
  
  cattr_accessor :privileges
  
  class << self
    def add_privileges(*privs)
      self.privileges ||= []
      privs.each do |priv|
        priv = priv.to_s
        self.privileges << priv
        class_eval <<-END
          def #{priv}?
            self.flags ||= {}
            self.flags[#{priv.inspect}] || false
          end
          def #{priv}=(v)
            self.flags ||= {}
            if [false, nil].include?(v)
              self.flags.delete(#{priv.inspect})
            else
              self.flags[#{priv.inspect}] = v
            end
          end
        END
      end
    end
    alias_method :add_privilege, :add_privileges
  end
  
  add_privileges *%w(
    view_hidden_profiles
    view_hidden_properties
    view_log
    edit_pages
    import_data
    export_data
    edit_profiles
    manage_publications
    manage_groups
    manage_notes
    manage_messages
    manage_comments
    manage_recipes
    manage_pictures
    manage_access
    manage_updates
    manage_news
    manage_attendance
    manage_sync
  )
end
