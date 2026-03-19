FactoryBot.define do
  factory :push_subscription do
    association :user
    sequence(:endpoint) { |n| "https://push.example.com/subscriptions/#{n}" }
    expiration_time { nil }
    sequence(:auth_key) { |n| "auth-key-#{n}" }
    sequence(:p256dh_key) { |n| "p256dh-key-#{n}" }
    user_agent { "RSpec" }
  end
end
