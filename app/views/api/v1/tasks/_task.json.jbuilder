json.extract! task,
              :id,
              :user_id,
              :title,
              :description,
              :rrule,
              :starts_at,
              :carry_over,
              :active,
              :created_at,
              :updated_at

json.occurrences task.task_occurrences,
                 partial: "api/v1/tasks/task_occurrence",
                 as: :task_occurrence
