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

    it "requires user, title, starts_at and timezone" do
      task = build(:task, user: nil, title: nil, starts_at: nil, timezone: nil)

      expect(task).not_to be_valid

      expect(task.errors[:user]).to include("must exist")
      expect(task.errors[:title]).to include("can't be blank")
      expect(task.errors[:starts_at]).to include("can't be blank")
      expect(task.errors[:timezone]).to include("can't be blank")
    end
  end

  describe "#set_default_timezone" do
    it "defaults timezone from the user on build/validation" do
      user = build(:user, timezone: "America/New_York")
      task = build(:task, user:)

      expect(task).to be_valid
      expect(task.timezone).to eq("America/New_York")
    end

    it "does not overwrite an explicit timezone" do
      user = build(:user, timezone: "America/New_York")
      task = build(:task, user:, timezone: "Europe/Paris")

      expect(task).to be_valid
      expect(task.timezone).to eq("Europe/Paris")
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
