FactoryGirl.define do
  factory :custom_field_value do
    association :field, factory: :custom_field
  end
end
