module CarryOver
  class ReconciliationRunner
    def self.call(reference_time: Time.current)
      new(reference_time:).call
    end

    def initialize(reference_time:)
      @reference_time = reference_time
    end

    def call
      configured_timezones.each do |timezone|
        next unless run_window_open?(timezone)

        ReconciliationService.call(timezone:, reference_time:)
        Notifications::MorningSummaryRunner.call(timezone:, reference_time:)
      end
    end

    private

    attr_reader :reference_time

    def configured_timezones
      Array(Rails.configuration.x.carry_over.timezones).compact
    end

    def run_window_open?(timezone)
      now_local = reference_time.in_time_zone(timezone)
      now_local.hour.zero? && now_local.min < run_window_minutes
    end

    def run_window_minutes
      Rails.configuration.x.carry_over.run_window_minutes
    end
  end
end
