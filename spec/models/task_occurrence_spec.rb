require 'rails_helper'

RSpec.describe TaskOccurrence, type: :model do
  before do
    @user = build(:user)
    @task = build(:task, user: @user)
  end

  describe "validations" do
    it "creates a valid task_occurrence" do
      task_occurrence = build(:task_occurrence, task: @task)

      expect(task_occurrence).to be_valid
    end

    it "requires task, occurred_at and status" do
      task_occurrence = build(:task_occurrence, task: nil, occurred_at: nil, status: nil)

      expect(task_occurrence).not_to be_valid

      expect(task_occurrence.errors[:task]).to include("must exist")
      expect(task_occurrence.errors[:occurred_at]).to include("can't be blank")
      expect(task_occurrence.errors[:status]).to include("can't be blank")
    end

    it "expects a valid status" do
      expect {
        build(:task_occurrence, task: @task, status: "TEST")
      }.to raise_error(ArgumentError).with_message("'TEST' is not a valid status")
    end
  end
end
