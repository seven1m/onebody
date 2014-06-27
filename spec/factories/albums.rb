FactoryGirl.define do
  factory :album do
    sequence(:name) { |n| "Album #{n}" }

    association :owner, factory: :person
  end
end
