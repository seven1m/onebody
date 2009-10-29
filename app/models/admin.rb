# == Schema Information
#
# Table name: admins
#
#  id                     :integer       not null, primary key
#  manage_publications    :boolean       
#  manage_log             :boolean       
#  manage_music           :boolean       
#  view_hidden_properties :boolean       
#  edit_profiles          :boolean       
#  manage_groups          :boolean       
#  manage_shares          :boolean       
#  manage_notes           :boolean       
#  manage_messages        :boolean       
#  view_hidden_profiles   :boolean       
#  manage_prayer_signups  :boolean       
#  manage_comments        :boolean       
#  manage_recipes         :boolean       
#  manage_pictures        :boolean       
#  manage_access          :boolean       
#  view_log               :boolean       
#  manage_updates         :boolean       
#  created_at             :datetime      
#  updated_at             :datetime      
#  site_id                :integer       
#  manage_checkin         :boolean       
#  edit_pages             :boolean       
#  import_data            :boolean       
#  export_data            :boolean       
#  run_reports            :boolean       
#  manage_news            :boolean       
#  manage_attendance      :boolean       
#  assign_checkin_cards   :boolean
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
    manage_checkin
    manage_news
    manage_attendance
    assign_checkin_cards
  )
end
