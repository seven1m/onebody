module Api
  module V2
    class FamilyResource < OneBodyResource
      attributes :name, :last_name, :suffix, :address1, :address2, :city,
                 :state, :zip, :home_phone, :email, :country, :site_id,
                 :legacy_id

      has_many :people
    end
  end
end