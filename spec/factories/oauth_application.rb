FactoryGirl.define do
  factory :oauth_application, class: Doorkeeper::Application do
    name 'My Test App'
    redirect_uri 'https://127.0.0.1'
  end
end
