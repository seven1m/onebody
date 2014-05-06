FactoryGirl.define do
  factory :group do
    sequence(:name) { |n| "Small Group #{n}" }
    category 'small groups'
    approved true
    hidden false
  end
end
