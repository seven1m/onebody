FactoryGirl.define do
  factory :checkin_label do
    name 'Check-in Label'
    description 'This is our check-in label.'
    xml '<?xml version="1.0" encoding="utf-8"?><foo/>'

    trait :file do
      xml '<?xml version="1.0" encoding="utf-8"?><file src="default.xml"/>'
    end
  end
end
