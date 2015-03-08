FactoryGirl.define do
  factory :import_row do
    import
    status 'pending'
    sequence(:sequence)

    trait :with_attributes do
      after(:create) do |row|
        row.import_attributes.create!(import: row.import, name: 'foo', value: 'bar', sequence: 1)
        row.import_attributes.create!(import: row.import, name: 'baz', value: 'quz', sequence: 2)
      end
    end
  end
end
