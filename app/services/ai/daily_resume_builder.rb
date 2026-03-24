module Ai
  class DailyResumeBuilder
    def self.call(user:, reference_time: Time.current)
      new(user:, reference_time:).call
    end

    def initialize(user:, reference_time:)
      @user = user
      @reference_time = reference_time
      @zone = ActiveSupport::TimeZone[user.timezone] || Time.zone
    end

    def call
      {
        date: target_date.iso8601,
        full_name: [ user.first_name, user.last_name ].join(" ").strip,
        due_today_count: due_today_tasks.count,
        late_count: late_task_titles.count,
        task_titles: actionable_task_titles
      }
    end

    private

    attr_reader :reference_time, :user, :zone

    def actionable_task_titles
      @actionable_task_titles ||= (due_today_tasks.map(&:title) + late_task_titles).uniq
    end

    def due_today_tasks
      @due_today_tasks ||= user.tasks.where(active: true).select { |task| due_today?(task) }
    end

    def due_today?(task)
      return recurrence_occurrences_for_today(task).any? if task.rrule.present?

      task.starts_at.in_time_zone(zone).to_date == target_date
    end

    def late_task_titles
      @late_task_titles ||= Task.joins(:task_occurrences)
                                .where(user:, carry_over: true, task_occurrences: { status: :missed })
                                .where(task_occurrences: { occurred_at: ...target_day_start })
                                .order("task_occurrences.occurred_at ASC")
                                .pluck(:title)
    end

    def recurrence_occurrences_for_today(task)
      rule = RRule::Rule.new(task.rrule, dtstart: task.starts_at.in_time_zone(zone), tzid: user.timezone)
      rule.between(target_day_start, target_day_end - 1.second)
    rescue StandardError
      []
    end

    def target_date
      @target_date ||= reference_time.in_time_zone(zone).to_date
    end

    def target_day_end
      @target_day_end ||= target_day_start.tomorrow
    end

    def target_day_start
      @target_day_start ||= zone.local(target_date.year, target_date.month, target_date.day).beginning_of_day
    end
  end
end
