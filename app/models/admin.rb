class Admin < ActiveRecord::Base
  has_many :people, dependent: :nullify
  def person; people.first; end # only admin templates have more than one

  belongs_to :site

  def self.people_count
    all.inject(0) { |sum, admin| sum += admin.people.count; sum }
  end

  scope_by_site_id

  serialize :flags

  def template?
    !template_name.nil?
  end

  validates_uniqueness_of :template_name, allow_nil: true, scope: :site_id

  before_save :ensure_flags_is_hash

  def ensure_flags_is_hash
    self.flags = {} if not flags.is_a?(Hash)
  end

  cattr_accessor :privileges

  class << self
    # only the privileges available in the locale file, along with title and description
    # and also in the correct sorted order from the locale
    def privileges_for_show
      I18n.t('admin.privileges').select do |name, priv|
        privileges.include?(name.to_s)
      end.sort_by do |name, priv|
        priv[:order].is_a?(Fixnum) ? '%03d' % priv[:order] : priv[:order].to_s
      end.map do |name, priv|
        priv[:name] = name.to_s
        priv
      end
    end

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
    edit_pages
    edit_profiles
    export_data
    import_data
    manage_access
    manage_attendance
    manage_comments
    manage_groups
    manage_news
    manage_pictures
    manage_prayer_signups
    manage_updates
    view_hidden_profiles
    view_hidden_properties
    view_log
    assign_checkin_cards
    manage_checkin
    manage_documents
    run_reports
    manage_reports
    manage_event_registration
  )

  Dir["#{Rails.root}/plugins/**/config/privileges.rb"].each do |path|
    load(path)
  end
end
