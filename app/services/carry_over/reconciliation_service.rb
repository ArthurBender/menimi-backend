module CarryOver
  class ReconciliationService
    def self.call(timezone:, reference_time: Time.current)
      new(timezone:, reference_time:).call
    end

    def initialize(timezone:, reference_time:)
      @timezone = timezone
      @reference_time = reference_time
      @zone = ActiveSupport::TimeZone[timezone]
    end

    def call
      return unless zone

      Task.where(active: true, timezone:).find_each do |task|
        reconcile_task(task)
      end
    end

    private

    attr_reader :timezone, :reference_time, :zone

    def reconcile_task(task)
      return unless due_on_target_date?(task)
      return if occurrence_exists_for_target_date?(task)

      task.task_occurrences.create!(
        occurred_at: due_occurrence_time(task),
        status: :missed
      )
    end

    def due_on_target_date?(task)
      if task.rrule.present?
        recurrence_occurrences_for_target_date(task).any?
      else
        task.starts_at.in_time_zone(zone).to_date == target_date
      end
    end

    def due_occurrence_time(task)
      return recurrence_occurrences_for_target_date(task).first if task.rrule.present?

      task.starts_at
    end

    def recurrence_occurrences_for_target_date(task)
      rule = RRule::Rule.new(task.rrule, dtstart: task.starts_at.in_time_zone(zone), tzid: timezone)
      rule.between(target_day_start, target_day_end - 1.second)
    rescue StandardError
      []
    end

    def occurrence_exists_for_target_date?(task)
      task.task_occurrences.where(occurred_at: target_day_start...target_day_end).exists?
    end

    def target_date
      @target_date ||= reference_time.in_time_zone(zone).to_date.yesterday
    end

    def target_day_start
      @target_day_start ||= zone.local(target_date.year, target_date.month, target_date.day).beginning_of_day
    end

    def target_day_end
      @target_day_end ||= target_day_start.tomorrow
    end
  end
end
