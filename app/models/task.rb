class Task < ApplicationRecord
  belongs_to :user
  has_many :task_occurrences, dependent: :destroy

  validates :title, :starts_at, :timezone, presence: true
  validates :carry_over, :active, inclusion: { in: [ true, false ] }

  validate :rrule_must_be_valid

  private

  def rrule_must_be_valid
    return if rrule.blank?

    RRule::Rule.new(rrule)
  rescue StandardError
    errors.add(:rrule, "must be a valid RRULE")
  end
end
