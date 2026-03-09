class CarryOverReconciliationJob < ApplicationJob
  queue_as :default

  def perform
    CarryOver::ReconciliationRunner.call
  end
end
