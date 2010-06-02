class Donortools::Donation < ActiveResource::Base

  # same resource is prefixed or not based on parameters
  def self.prefix(options={})
    if options[:persona_id]
      "/personas/#{options[:persona_id]}/"
    else
      "/"
    end
  end

  def self.prefix_parameters
    []
  end

  def donation_type
    I18n.t("d#{donation_type_id}", :scope => ['contributions', 'donation_types'])
  end

  attr_accessor :person

  class << self
    def all(params={}, options={})
      if params.any?
        donations = find(:all, :params => params)
      else
        donations = find(:all)
      end
      # do our own eager loading
      if options[:include] == :person
        persona_ids = donations.map { |d| d.persona_id }
        people = Person.all(:conditions => ["donortools_id in (?)", persona_ids]).group_by(&:donortools_id)
        donations.each do |donation|
          donation.person = people[donation.persona_id] && people[donation.persona_id][0]
        end
      end
      donations
    end

    def setup_connection
      self.site     = Setting.get(:services, :donor_tools_url)
      self.user     = Setting.get(:services, :donor_tools_api_email)
      self.password = Setting.get(:services, :donor_tools_api_password)
      true
    end
  end
end