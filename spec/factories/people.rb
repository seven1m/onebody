FactoryGirl.define do
  factory :person do
    first_name 'John'
    last_name 'Smith'
    gender 'Male'
    sequence(:email) { |n| "jsmith#{n}@example.com" }
    password 'secret'
    child false
    status :active
    family

    trait :super_admin do
      admin { Admin.create!(super_admin: true) }
    end

    trait :admin_edit_profiles do
      admin { Admin.create!(edit_profiles: true) }
    end

    trait :admin_manage_updates do
      admin { Admin.create!(manage_updates: true) }
    end

    trait :admin_manage_groups do
      admin { Admin.create!(manage_groups: true) }
    end

    trait :admin_import_data do
      admin { Admin.create!(import_data: true) }
    end

    trait :admin_manage_checkin do
      admin { Admin.create!(manage_checkin: true) }
    end

    trait :with_business do
      business_category 'Home Improvement'
      business_name 'ABC Home Improvement'
    end
  end
end
