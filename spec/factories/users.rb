FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    first_name { "John" }
    language { "en" }
    last_name { "Doe" }
    timezone { "UTC" }
    password { "password123" }
    password_confirmation { "password123" }
    jti { SecureRandom.uuid }
  end
end
