require "rails_helper"

RSpec.describe Notifications::MorningSummaryRunner do
  describe ".call" do
    around do |example|
      old_timezones = Rails.configuration.x.notifications.morning_summary.timezones
      old_window = Rails.configuration.x.notifications.morning_summary.run_window_minutes

      Rails.configuration.x.notifications.morning_summary.timezones = [ "America/Sao_Paulo", "UTC" ]
      Rails.configuration.x.notifications.morning_summary.run_window_minutes = 15

      example.run

      Rails.configuration.x.notifications.morning_summary.timezones = old_timezones
      Rails.configuration.x.notifications.morning_summary.run_window_minutes = old_window
    end

    it "sends notifications only for timezones inside midnight window" do
      reference_time = Time.use_zone("America/Sao_Paulo") { Time.zone.parse("2026-03-10 00:05:00") }
      user = create(:user, timezone: "America/Sao_Paulo")
      create(:push_subscription, user:)
      payload = { title: "Daily task summary", body: "Hello", url: "/calendar" }

      allow(Notifications::MorningSummaryPayloadBuilder).to receive(:call).and_return(payload)
      allow(Notifications::WebPushDeliveryService).to receive(:call)

      described_class.call(reference_time:)

      expect(Notifications::MorningSummaryPayloadBuilder).to have_received(:call)
        .with(user:, reference_time:)
      expect(Notifications::WebPushDeliveryService).to have_received(:call)
        .with(user:, payload:)
    end

    it "does not send notifications outside the midnight window" do
      reference_time = Time.use_zone("America/Sao_Paulo") { Time.zone.parse("2026-03-10 00:20:00") }

      allow(Notifications::MorningSummaryPayloadBuilder).to receive(:call)
      allow(Notifications::WebPushDeliveryService).to receive(:call)

      described_class.call(reference_time:)

      expect(Notifications::MorningSummaryPayloadBuilder).not_to have_received(:call)
      expect(Notifications::WebPushDeliveryService).not_to have_received(:call)
    end
  end
end
