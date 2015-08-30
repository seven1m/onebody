FactoryGirl.define do
  factory :import_row do
    import
    sequence(:sequence)

    trait :with_attributes do
      after(:create) do |row|
        row.import_attributes.create!(import: row.import, name: 'first', value: 'foo', sequence: 1)
        row.import_attributes.create!(import: row.import, name: 'last',  value: 'bar', sequence: 2)
      end
    end
  end
end
