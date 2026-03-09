require "rails_helper"

RSpec.describe CarryOver::ReconciliationRunner do
  describe ".call" do
    around do |example|
      old_timezones = Rails.configuration.x.carry_over.timezones
      old_window = Rails.configuration.x.carry_over.run_window_minutes

      Rails.configuration.x.carry_over.timezones = [ "America/Sao_Paulo", "UTC" ]
      Rails.configuration.x.carry_over.run_window_minutes = 15

      example.run

      Rails.configuration.x.carry_over.timezones = old_timezones
      Rails.configuration.x.carry_over.run_window_minutes = old_window
    end

    it "runs reconciliation only for timezones inside midnight window" do
      reference_time = Time.use_zone("America/Sao_Paulo") { Time.zone.parse("2026-03-10 00:05:00") }

      allow(CarryOver::ReconciliationService).to receive(:call)

      described_class.call(reference_time:)

      expect(CarryOver::ReconciliationService).to have_received(:call)
        .with(timezone: "America/Sao_Paulo", reference_time:)
      expect(CarryOver::ReconciliationService).not_to have_received(:call)
        .with(timezone: "UTC", reference_time:)
    end

    it "does not run reconciliation outside the midnight window" do
      reference_time = Time.use_zone("America/Sao_Paulo") { Time.zone.parse("2026-03-10 00:20:00") }

      allow(CarryOver::ReconciliationService).to receive(:call)

      described_class.call(reference_time:)

      expect(CarryOver::ReconciliationService).not_to have_received(:call)
    end
  end
end
