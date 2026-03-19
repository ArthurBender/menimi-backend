require "rails_helper"

RSpec.describe Notifications::MorningSummaryPayloadBuilder do
  describe ".call" do
    let(:timezone) { "America/Sao_Paulo" }
    let(:reference_time) { Time.use_zone(timezone) { Time.zone.parse("2026-03-10 00:05:00") } }
    let(:user) { create(:user, timezone:, first_name: "Jane", last_name: "Doe") }

    it "builds a payload with today's tasks and late carry-over tasks" do
      create(
        :task,
        user:,
        title: "Review inbox",
        carry_over: true,
        starts_at: Time.use_zone(timezone) { Time.zone.parse("2026-03-10 09:00:00") }
      )
      create(
        :task,
        user:,
        title: "Plan sprint",
        carry_over: true,
        starts_at: Time.use_zone(timezone) { Time.zone.parse("2026-03-01 08:00:00") },
        rrule: "FREQ=DAILY;INTERVAL=1"
      )
      late_task = create(
        :task,
        user:,
        title: "Pay bills",
        carry_over: true,
        starts_at: Time.use_zone(timezone) { Time.zone.parse("2026-03-08 08:00:00") }
      )
      create(
        :task_occurrence,
        task: late_task,
        status: "missed",
        occurred_at: Time.use_zone(timezone) { Time.zone.parse("2026-03-09 08:00:00") }
      )

      payload = described_class.call(user:, reference_time:)

      expect(payload).to eq(
        title: "Daily task summary",
        body: "Good morning, Jane Doe!\nYou have 3 tasks for today, from which 1 are late:\n- Review inbox\n- Plan sprint\n+1 more",
        url: "/calendar"
      )
    end

    it "omits the late clause when there are no late carry-over tasks" do
      create(
        :task,
        user:,
        title: "Go for a walk",
        carry_over: false,
        starts_at: Time.use_zone(timezone) { Time.zone.parse("2026-03-10 09:00:00") }
      )

      payload = described_class.call(user:, reference_time:)

      expect(payload).to eq(
        title: "Daily task summary",
        body: "Good morning, Jane Doe!\nYou have 1 tasks for today:\n- Go for a walk",
        url: "/calendar"
      )
    end
  end
end
