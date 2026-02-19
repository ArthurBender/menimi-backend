FactoryBot.define do
  factory :task do
    title { "Task title" }
    starts_at { Time.now }
  end
end
