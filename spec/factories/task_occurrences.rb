FactoryBot.define do
  factory :task_occurrence do
    occurred_at { Time.now }
    status { "done" }
  end
end
