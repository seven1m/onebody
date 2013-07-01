FactoryGirl.define do
  factory :person do
    first_name 'John'
    last_name 'Smith'
    gender 'Male'
    sequence(:email) { |n| "jsmith#{n}@example.com" }
    password 'secret'
    child false
    visible_to_everyone true
    visible true
    can_sign_in true
    full_access true
    family

    trait :admin_edit_profiles do
      admin { Admin.create!(edit_profiles: true) }
    end

    trait :admin_manage_updates do
      admin { Admin.create!(manage_updates: true) }
    end
  end
end
