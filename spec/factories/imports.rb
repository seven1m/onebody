FactoryGirl.define do
  factory :import do
    person
    filename        'foo.csv'
    importable_type 'Person'
    status          'pending'
  end
end
