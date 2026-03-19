class MorningSummaryNotificationsJob < ApplicationJob
  queue_as :default

  def perform
    Notifications::MorningSummaryRunner.call
  end
end
