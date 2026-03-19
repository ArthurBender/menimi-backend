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
      {
        title: "Daily task summary",
        body:,
        url: "/calendar"
      }
    end

    private

    attr_reader :user, :reference_time, :zone

    def body
      late_count = late_tasks_count
      header = "Good morning, #{user.first_name} #{user.last_name}!"
      summary = "You have #{total_tasks_count(late_count)} tasks for today"
      summary = if late_count.zero?
        "#{summary}:"
      else
        "#{summary}, from which #{late_count} are late:"
      end

      return [ header, summary ].join("\n") if task_preview_lines.empty?

      [ header, summary, nil, *task_preview_lines ].compact.join("\n")
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

    def late_tasks_count
      TaskOccurrence.joins(:task)
                    .where(status: :missed, tasks: { user_id: user.id, carry_over: true })
                    .where(occurred_at: ...target_day_start)
                    .count
    end

    def task_preview_lines
      titles = actionable_task_titles
      return [] if titles.empty?

      preview_titles = titles.first(2).map { |title| "- #{title}" }
      remaining_count = titles.size - 2

      return preview_titles if remaining_count <= 0

      [ *preview_titles, "+#{remaining_count} more" ]
    end

    def actionable_task_titles
      @actionable_task_titles ||= (due_today_task_titles + late_task_titles).uniq
    end

    def due_today_task_titles
      due_today_tasks.sort_by(&:starts_at).map(&:title)
    end

    def late_task_titles
      Task.joins(:task_occurrences)
          .where(user:, carry_over: true, task_occurrences: { status: :missed })
          .where(task_occurrences: { occurred_at: ...target_day_start })
          .order("task_occurrences.occurred_at ASC")
          .pluck(:title)
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
