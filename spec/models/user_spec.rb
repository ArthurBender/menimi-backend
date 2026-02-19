require 'rails_helper'

RSpec.describe User, type: :model do
  describe "validations" do
    it "creates a valid user" do
      user = build(:user)

      expect(user).to be_valid
    end

    it "requires email, first_name and last_name" do
      user = build(:user, email: nil, first_name: nil, last_name: nil)

      expect(user).not_to be_valid

      expect(user.errors[:email]).to include("can't be blank")
      expect(user.errors[:first_name]).to include("can't be blank")
      expect(user.errors[:last_name]).to include("can't be blank")
    end

    it "requires email to be unique" do
      create(:user, email: "user@example.com")
      user = build(:user, email: "user@example.com")

      expect(user).not_to be_valid
    end
  end

  describe "associations" do
    before do
      @user = create(:user)
      @task = create(:task, user: @user)
    end

    it "has many tasks" do
      expect(@user.tasks).to include(@task)
    end

    it "has dependent tasks" do
      expect {
        @user.destroy
      }.to change { Task.count }.by(-1)
    end
  end
end
