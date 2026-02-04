class TaskOccurrence < ApplicationRecord
  belongs_to :task

  validates :occurred_at, :status, presence: true

  enum :status, {
    missed: "missed",
    canceled: "canceled",
    done: "done"
  }, prefix: true
end
