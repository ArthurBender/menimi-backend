return unless defined?(Sidekiq)
require "sidekiq/cron/job"

schedule_path = Rails.root.join("config/sidekiq_schedule.yml")

if Sidekiq.server? && File.exist?(schedule_path)
  Sidekiq.configure_server do |_config|
    schedule = YAML.safe_load_file(schedule_path, aliases: true) || {}
    entries = schedule.fetch(Rails.env, {})

    Sidekiq::Cron::Job.load_from_hash(entries) if entries.any?
  end
end
