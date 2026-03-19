require "rails_helper"

RSpec.describe Notifications::WebPushDeliveryService do
  describe ".call" do
    let(:user) { create(:user) }
    let!(:push_subscription) { create(:push_subscription, user:) }
    let(:payload) { { title: "Daily task summary", body: "Hello", url: "/calendar" } }

    around do |example|
      old_subject = ENV["VAPID_SUBJECT"]
      old_public_key = ENV["VAPID_PUBLIC_KEY"]
      old_private_key = ENV["VAPID_PRIVATE_KEY"]

      ENV["VAPID_SUBJECT"] = "mailto:test@example.com"
      ENV["VAPID_PUBLIC_KEY"] = "public-key"
      ENV["VAPID_PRIVATE_KEY"] = "private-key"

      example.run

      ENV["VAPID_SUBJECT"] = old_subject
      ENV["VAPID_PUBLIC_KEY"] = old_public_key
      ENV["VAPID_PRIVATE_KEY"] = old_private_key
    end

    it "delivers the payload to each push subscription" do
      allow(WebPush).to receive(:payload_send)

      described_class.call(user:, payload:)

      expect(WebPush).to have_received(:payload_send).with(
        endpoint: push_subscription.endpoint,
        message: payload.to_json,
        p256dh: push_subscription.p256dh_key,
        auth: push_subscription.auth_key,
        vapid: {
          subject: "mailto:test@example.com",
          public_key: "public-key",
          private_key: "private-key"
        },
        ttl: 1.day.to_i
      )
    end

    it "deletes stale subscriptions returned by the push service" do
      response = instance_double(Net::HTTPGone, body: "", inspect: "#<response>")
      error = WebPush::ExpiredSubscription.new(response, URI(push_subscription.endpoint).host)
      allow(WebPush).to receive(:payload_send).and_raise(error)

      expect {
        described_class.call(user:, payload:)
      }.to change(PushSubscription, :count).by(-1)
    end
  end
end
