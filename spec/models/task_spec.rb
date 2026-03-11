require 'rails_helper'

RSpec.describe Task, type: :model do
  before do
    @user = build(:user)
  end

  describe "validations" do
    it "creates a valid task" do
      task = build(:task, user: @user)

      expect(task).to be_valid
    end

    it "requires user, title and starts_at" do
      task = build(:task, user: nil, title: nil, starts_at: nil)

      expect(task).not_to be_valid

      expect(task.errors[:user]).to include("must exist")
      expect(task.errors[:title]).to include("can't be blank")
      expect(task.errors[:starts_at]).to include("can't be blank")
    end
  end

  describe "associations" do
    before do
      @user = create(:user)
      @task = create(:task, user: @user)
      @task_occurrence = create(:task_occurrence, task: @task)
    end

    it "has many task_occurrences" do
      expect(@task.task_occurrences).to include(@task_occurrence)
    end

    it "belongs to user" do
      expect(@task.user).to eq(@user)
    end

    it "has dependant task_occurrences" do
      expect {
        @task.destroy
      }.to change { TaskOccurrence.count }.by(-1)
    end
  end

  describe "#rrule_must_be_valid" do
    it "creates a task with valid rrule" do
      task = build(:task, user: @user, rrule: "RRULE:FREQ=DAILY")

      expect(task).to be_valid
    end

    it "does not create a task with invalid rrule" do
      task = build(:task, user: @user, rrule: "TEST")

      expect(task).not_to be_valid
    end
  end
end
