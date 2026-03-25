module Notifications
  class MorningSummaryRunner
    def self.call(timezone:, reference_time: Time.current)
      new(timezone:, reference_time:).call
    end

    def initialize(timezone:, reference_time:)
      @timezone = timezone
      @reference_time = reference_time
    end

    def call
      users_for_timezone.find_each do |user|
        payload = MorningSummaryPayloadBuilder.call(user:, reference_time:)
        WebPushDeliveryService.call(user:, payload:)
      end
    end

    private

    attr_reader :reference_time, :timezone

    def users_for_timezone
      User.joins(:push_subscriptions).where(timezone:).distinct
    end
  end
end
