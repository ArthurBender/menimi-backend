module Notifications
  class MorningSummaryRunner
    def self.call(reference_time: Time.current)
      new(reference_time:).call
    end

    def initialize(reference_time:)
      @reference_time = reference_time
    end

    def call
      configured_timezones.each do |timezone|
        # next unless run_window_open?(timezone)

        users_for_timezone(timezone).find_each do |user|
          payload = MorningSummaryPayloadBuilder.call(user:, reference_time:)
          WebPushDeliveryService.call(user:, payload:)
        end
      end
    end

    private

    attr_reader :reference_time

    def configured_timezones
      Array(Rails.configuration.x.notifications.morning_summary.timezones).compact
    end

    def users_for_timezone(timezone)
      User.joins(:push_subscriptions).where(timezone:).distinct
    end

    def run_window_open?(timezone)
      now_local = reference_time.in_time_zone(timezone)
      now_local.hour.zero? && now_local.min < run_window_minutes
    end

    def run_window_minutes
      Rails.configuration.x.notifications.morning_summary.run_window_minutes
    end
  end
end
