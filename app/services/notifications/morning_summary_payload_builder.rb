module Notifications
  class MorningSummaryPayloadBuilder
    def self.call(user:, reference_time: Time.current)
      new(user:, reference_time:).call
    end

    def initialize(user:, reference_time:)
      @user = user
      @reference_time = reference_time
      @zone = ActiveSupport::TimeZone[user.timezone]
    end

    def call
      I18n.with_locale(user.locale) do
        {
          title: I18n.t("notifications.morning_summary.title"),
          body:,
          url: "/calendar"
        }
      end
    end

    private

    attr_reader :user, :reference_time, :zone

    def body
      I18n.with_locale(user.locale) do
        late_count = late_tasks_count
        header = I18n.t(
          "notifications.morning_summary.header",
          first_name: user.first_name,
          last_name: user.last_name
        )
        summary = if late_count.zero?
          I18n.t("notifications.morning_summary.summary", count: total_tasks_count(late_count))
        else
          I18n.t("notifications.morning_summary.summary_with_late", count: total_tasks_count(late_count), late_count:)
        end

        return [ header, summary ].join("\n") if task_preview_lines.empty?

        [ header, summary, nil, *task_preview_lines ].compact.join("\n")
      end
    end

    def total_tasks_count(late_tasks_count)
      due_today_tasks_count + late_tasks_count
    end

    def due_today_tasks_count
      due_today_tasks.size
    end

    def due_today_tasks
      @due_today_tasks ||= user.tasks.where(active: true).select { |task| due_today?(task) }
    end

    def due_today?(task)
      return recurrence_occurrences_for_today(task).any? if task.rrule.present?

      task.starts_at.in_time_zone(zone).to_date == target_date
    end

    def recurrence_occurrences_for_today(task)
      rule = RRule::Rule.new(task.rrule, dtstart: task.starts_at.in_time_zone(zone), tzid: user.timezone)
      rule.between(target_day_start, target_day_end - 1.second)
    rescue StandardError
      []
    end

    def late_tasks
      @late_tasks ||= Task.where(user:, carry_over: true, active: true)
                          .includes(:task_occurrences)
                          .select { |task| late_carry_over?(task) }
    end

    def late_carry_over?(task)
      past = task.task_occurrences.select { |occ| occ.occurred_at < target_day_start }
      return false if past.empty?

      past.max_by(&:occurred_at).status_missed?
    end

    def late_tasks_count
      late_tasks.size
    end

    def task_preview_lines
      titles = actionable_task_titles
      return [] if titles.empty?

      preview_titles = titles.first(2).map { |title| "- #{title}" }
      remaining_count = titles.size - 2

      return preview_titles if remaining_count <= 0

      [ *preview_titles, I18n.t("notifications.morning_summary.more", count: remaining_count) ]
    end

    def actionable_task_titles
      @actionable_task_titles ||= (due_today_task_titles + late_task_titles).uniq
    end

    def due_today_task_titles
      due_today_tasks.map(&:title)
    end

    def late_task_titles
      late_tasks.map(&:title).uniq
    end

    def target_date
      @target_date ||= reference_time.in_time_zone(zone).to_date
    end

    def target_day_start
      @target_day_start ||= zone.local(target_date.year, target_date.month, target_date.day).beginning_of_day
    end

    def target_day_end
      @target_day_end ||= target_day_start.tomorrow
    end
  end
end
