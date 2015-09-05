FactoryGirl.define do
  factory :import_row do
    import
    sequence(:sequence)

    trait :with_attributes do
      import_attributes(first: 'foo', last: 'bar')
    end
  end
end
