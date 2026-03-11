User.destroy_all
Task.destroy_all
TaskOccurrence.destroy_all
puts "[SEEDS] Database successfully cleaned."

user = User.find_or_initialize_by(email: "arthur@example.com")
user.update!(
  first_name: "Arthur",
  last_name: "Dev",
  timezone: "America/Sao_Paulo"
)

tasks = [
  {
    title: "Daily journal",
    description: "Write a short daily journal entry.",
    rrule: "FREQ=DAILY;INTERVAL=1",
    starts_at: "2026-02-01 08:00",
    carry_over: false,
    active: true
  },
  {
    title: "Gym session",
    description: "Strength training workout.",
    rrule: "FREQ=WEEKLY;BYDAY=MO,WE,FR",
    starts_at: "2026-02-03 18:30",
    carry_over: true,
    active: true
  },
  {
    title: "Pay rent",
    description: "Monthly rent payment.",
    rrule: "FREQ=MONTHLY;BYMONTHDAY=5",
    starts_at: "2026-02-05 09:00",
    carry_over: false,
    active: true
  },
  {
    title: "Read a book",
    description: "Read for 30 minutes.",
    rrule: nil,
    starts_at: "2026-02-04 21:00",
    carry_over: false,
    active: true
  }
]

task_records = tasks.map do |attributes|
  starts_at = Time.use_zone(user.timezone) do
    Time.zone.parse(attributes.fetch(:starts_at))
  end

  task = Task.find_or_initialize_by(user: user, title: attributes.fetch(:title))
  task.update!(attributes.merge(starts_at: starts_at))
  task
end

occurrences_by_task_title = {
  "Daily journal" => [
    [ "2026-03-02 08:10", "done" ],
    [ "2026-03-03 08:05", "done" ],
    [ "2026-03-04 08:40", "missed" ]
  ],
  "Gym session" => [
    [ "2026-03-02 19:10", "done" ],
    [ "2026-03-04 19:20", "done" ]
  ],
  "Pay rent" => [
    [ "2026-03-05 09:05", "done" ],
    [ "2026-03-06 09:05", "canceled" ]
  ]
}

task_records.each do |task|
  next unless occurrences_by_task_title.key?(task.title)

  occurrences_by_task_title.fetch(task.title).each do |occurred_at, status|
    occurred_time = Time.use_zone(task.user.timezone) { Time.zone.parse(occurred_at) }

    TaskOccurrence.find_or_create_by!(
      task: task,
      occurred_at: occurred_time,
      status: status
    )
  end
end

puts "[SEEDS] --------------------------------------------------"
puts "[SEEDS] Instances created: users=#{User.count}, tasks=#{Task.count}, occurrences=#{TaskOccurrence.count}."
