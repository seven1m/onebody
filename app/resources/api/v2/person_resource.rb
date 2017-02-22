module Api
  module V2
    class PersonResource < OneBodyResource
      attributes :gender, :first_name, :last_name, :suffix, :mobile_phone,
                 :work_phone, :fax, :birthday, :email, :website,
                 :shepherd, :business_name, :business_phone, :business_email,
                 :business_website, :alternate_email, :member, :staff,
                 :child, :site_id, :legacy_id

      has_one :family
      has_many :groups
      has_many :messages
      has_many :friends, class_name: 'Person'
    end
  end
end



