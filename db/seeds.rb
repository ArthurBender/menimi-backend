lambda do
  unless Rails.env.development?
    puts "[SEEDS] Skipping seeds because environment is #{Rails.env}."
    return
  end

  timezone = "America/Sao_Paulo"

  PushSubscription.destroy_all
  TaskOccurrence.destroy_all
  Task.destroy_all
  User.destroy_all

  puts "[SEEDS] Database successfully cleaned."

  user = User.create!(
    email: "arthur@example.com",
    password: "password123",
    password_confirmation: "password123",
    first_name: "Arthur",
    last_name: "Bender",
    timezone:
  )

  tasks = [
    {
      title: "Daily journal",
      description: "Write a short daily journal entry.",
      rrule: "FREQ=DAILY;INTERVAL=1",
      starts_at: "2026-03-01 08:00",
      carry_over: false,
      active: true
    },
    {
      title: "Gym session",
      description: "Strength training workout.",
      rrule: "FREQ=WEEKLY;BYDAY=MO,WE,FR",
      starts_at: "2026-03-02 18:30",
      carry_over: true,
      active: true
    },
    {
      title: "Pay rent",
      description: "Monthly rent payment.",
      rrule: "FREQ=MONTHLY;BYMONTHDAY=5",
      starts_at: "2026-03-05 09:00",
      carry_over: false,
      active: true
    },
    {
      title: "Book dentist",
      description: "Schedule the next dentist appointment.",
      rrule: nil,
      starts_at: "2026-03-07 14:00",
      carry_over: true,
      active: true
    },
    {
      title: "Plan weekly priorities",
      description: "Review tasks and define the top priorities for the week.",
      rrule: "FREQ=WEEKLY;BYDAY=SU",
      starts_at: "2026-03-08 10:00",
      carry_over: true,
      active: true
    }
  ]

  task_records = tasks.index_with do |attributes|
    starts_at = Time.use_zone(timezone) do
      Time.zone.parse(attributes.fetch(:starts_at))
    end

    Task.create!(attributes.merge(user:, starts_at:))
  end

  occurrences_by_title = {
    "Daily journal" => [
      [ "2026-03-15 08:05", "done" ],
      [ "2026-03-16 08:15", "done" ],
      [ "2026-03-17 08:30", "missed" ]
    ],
    "Gym session" => [
      [ "2026-03-16 19:05", "done" ],
      [ "2026-03-18 19:20", "missed" ]
    ],
    "Pay rent" => [
      [ "2026-03-05 09:10", "done" ]
    ],
    "Book dentist" => [
      [ "2026-03-07 14:00", "missed" ]
    ]
  }

  occurrences_by_title.each do |title, occurrences|
    task = task_records.fetch(title)

    occurrences.each do |occurred_at, status|
      TaskOccurrence.create!(
        task:,
        occurred_at: Time.use_zone(timezone) { Time.zone.parse(occurred_at) },
        status:
      )
    end
  end

  PushSubscription.create!(
    user:,
    endpoint: "https://push.example.test/subscriptions/arthur-primary",
    auth_key: "dev-auth-key",
    p256dh_key: "dev-p256dh-key",
    user_agent: "Seeded Browser"
  )

  puts "[SEEDS] --------------------------------------------------"
  puts "[SEEDS] Instances created: users=#{User.count}, tasks=#{Task.count}, occurrences=#{TaskOccurrence.count}, push_subscriptions=#{PushSubscription.count}."
end.call
