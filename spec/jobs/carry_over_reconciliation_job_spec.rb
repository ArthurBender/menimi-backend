require "rails_helper"

RSpec.describe CarryOverReconciliationJob, type: :job do
  it "delegates to reconciliation runner" do
    allow(CarryOver::ReconciliationRunner).to receive(:call)

    described_class.perform_now

    expect(CarryOver::ReconciliationRunner).to have_received(:call)
  end
end
