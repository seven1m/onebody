class ActiveRecord::Base
  def self.scope_by_site_id
    default_scope -> { Site.current ? where(site_id: Site.current.id) : raise('Site.current is nil') }
    belongs_to :site

    after_initialize do
      self.site = Site.current
    end
  end

  def self.digits_only_for_attributes=(attributes)
    attributes.each do |attribute|
      class_eval "
        def #{attribute}=(val)
          write_attribute :#{attribute}, val.to_s.digits_only
        end
      "
    end
  end
end
