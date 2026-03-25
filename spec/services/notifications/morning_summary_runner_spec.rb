require "rails_helper"

RSpec.describe Notifications::MorningSummaryRunner do
  describe ".call" do
    it "sends notifications for users in the given timezone" do
      reference_time = Time.use_zone("America/Sao_Paulo") { Time.zone.parse("2026-03-10 09:30:00") }
      user = create(:user, timezone: "America/Sao_Paulo")
      create(:push_subscription, user:)
      payload = { title: "Daily task summary", body: "Hello", url: "/calendar" }

      allow(Notifications::MorningSummaryPayloadBuilder).to receive(:call).and_return(payload)
      allow(Notifications::WebPushDeliveryService).to receive(:call)

      described_class.call(timezone: "America/Sao_Paulo", reference_time:)

      expect(Notifications::MorningSummaryPayloadBuilder).to have_received(:call)
        .with(user:, reference_time:)
      expect(Notifications::WebPushDeliveryService).to have_received(:call)
        .with(user:, payload:)
    end

    it "does not send notifications for users outside the given timezone" do
      reference_time = Time.use_zone("America/Sao_Paulo") { Time.zone.parse("2026-03-10 09:30:00") }
      user = create(:user, timezone: "UTC")
      create(:push_subscription, user:)

      allow(Notifications::MorningSummaryPayloadBuilder).to receive(:call)
      allow(Notifications::WebPushDeliveryService).to receive(:call)

      described_class.call(timezone: "America/Sao_Paulo", reference_time:)

      expect(Notifications::MorningSummaryPayloadBuilder).not_to have_received(:call)
      expect(Notifications::WebPushDeliveryService).not_to have_received(:call)
    end
  end
end
