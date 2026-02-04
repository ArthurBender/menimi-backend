class Task < ApplicationRecord
  belongs_to :user
  has_many :task_occurrences, dependent: :destroy

  validates :title, :starts_at, :timezone, presence: true
  validates :carry_over, :active, inclusion: { in: [ true, false ] }
end
