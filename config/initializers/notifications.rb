Rails.application.config.x.notifications ||= ActiveSupport::OrderedOptions.new
Rails.application.config.x.notifications.morning_summary ||= ActiveSupport::OrderedOptions.new
Rails.application.config.x.notifications.morning_summary.timezones = [ "America/Sao_Paulo" ].freeze
Rails.application.config.x.notifications.morning_summary.run_window_minutes = 15
