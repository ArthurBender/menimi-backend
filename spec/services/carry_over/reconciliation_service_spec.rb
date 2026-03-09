require "rails_helper"

RSpec.describe CarryOver::ReconciliationService do
  let(:timezone) { "America/Sao_Paulo" }
  let(:user) { create(:user, timezone:) }

  describe ".call" do
    it "creates missed occurrence for due non-recurrent task" do
      starts_at = Time.use_zone(timezone) { Time.zone.parse("2026-03-09 08:00:00") }
      task = create(:task, user:, timezone:, starts_at:, rrule: nil, active: true)
      reference_time = Time.use_zone(timezone) { Time.zone.parse("2026-03-10 00:05:00") }

      expect {
        described_class.call(timezone:, reference_time:)
      }.to change { task.task_occurrences.count }.by(1)

      occurrence = task.task_occurrences.order(:id).last
      expect(occurrence.status).to eq("missed")
      expect(occurrence.occurred_at).to eq(starts_at)
    end

    it "does not create missed occurrence when one already exists on target date" do
      starts_at = Time.use_zone(timezone) { Time.zone.parse("2026-03-09 08:00:00") }
      task = create(:task, user:, timezone:, starts_at:, rrule: nil, active: true)
      create(:task_occurrence, task:, status: "done", occurred_at: starts_at)
      reference_time = Time.use_zone(timezone) { Time.zone.parse("2026-03-10 00:05:00") }

      expect {
        described_class.call(timezone:, reference_time:)
      }.not_to change { task.task_occurrences.count }
    end

    it "creates missed occurrence for due recurrent task" do
      starts_at = Time.use_zone(timezone) { Time.zone.parse("2026-03-01 08:00:00") }
      task = create(:task, user:, timezone:, starts_at:, rrule: "FREQ=DAILY;INTERVAL=1", active: true)
      reference_time = Time.use_zone(timezone) { Time.zone.parse("2026-03-10 00:05:00") }

      expect {
        described_class.call(timezone:, reference_time:)
      }.to change { task.task_occurrences.count }.by(1)

      occurrence = task.task_occurrences.order(:id).last
      expect(occurrence.status).to eq("missed")
      expect(occurrence.occurred_at.in_time_zone(timezone).to_date).to eq(Date.new(2026, 3, 9))
    end

    it "is idempotent when called multiple times for the same target date" do
      starts_at = Time.use_zone(timezone) { Time.zone.parse("2026-03-01 08:00:00") }
      task = create(:task, user:, timezone:, starts_at:, rrule: "FREQ=DAILY;INTERVAL=1", active: true)
      reference_time = Time.use_zone(timezone) { Time.zone.parse("2026-03-10 00:05:00") }

      described_class.call(timezone:, reference_time:)

      expect {
        described_class.call(timezone:, reference_time:)
      }.not_to change { task.task_occurrences.count }
    end
  end
end
