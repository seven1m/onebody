FactoryGirl.define do
  factory :custom_field do
    association :tab, factory: :custom_field_tab
    name 'Age Group'
    format 'string'
  end
end
