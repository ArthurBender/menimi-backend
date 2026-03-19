module Notifications
  class WebPushDeliveryService
    def self.call(user:, payload:)
      new(user:, payload:).call
    end

    def initialize(user:, payload:)
      @user = user
      @payload = payload
    end

    def call
      return unless vapid_configured?

      user.push_subscriptions.find_each do |subscription|
        send_notification(subscription)
      rescue WebPush::InvalidSubscription, WebPush::ExpiredSubscription
        subscription.destroy!
      rescue WebPush::ResponseError => e
        Rails.logger.error("Web push delivery failed for PushSubscription #{subscription.id}: #{e.message}")
      end
    end

    private

    attr_reader :user, :payload

    def send_notification(subscription)
      WebPush.payload_send(
        endpoint: subscription.endpoint,
        message: payload.to_json,
        p256dh: subscription.p256dh_key,
        auth: subscription.auth_key,
        vapid: vapid_options,
        ttl: 1.day.to_i
      )
    end

    def vapid_options
      {
        subject: ENV.fetch("VAPID_SUBJECT"),
        public_key: ENV.fetch("VAPID_PUBLIC_KEY"),
        private_key: ENV.fetch("VAPID_PRIVATE_KEY")
      }
    end

    def vapid_configured?
      %w[VAPID_SUBJECT VAPID_PUBLIC_KEY VAPID_PRIVATE_KEY].all? { |key| ENV[key].present? }
    end
  end
end
