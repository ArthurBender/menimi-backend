require 'rails_helper'

RSpec.describe "Tasks", type: :request do
  before do
    @user = create(:user)
    @task = create(:task, user: @user)
    @task_occurrence = create(:task_occurrence, task: @task)
  end

  describe "GET /tasks" do
    it "returns tasks with the expected JSON fields" do
      get api_v1_tasks_path

      expect(response).to have_http_status(200)
      expect(response).to match_json_schema("tasks")
    end
  end

  describe "GET /tasks/:id" do
    it "returns a task with the expected JSON fields" do
      get api_v1_task_path(@task)

      expect(response).to have_http_status(200)
      expect(response).to match_json_schema("task")
    end

    it "returns a 404 if the task does not exist" do
      get api_v1_task_path(0)

      expect(response).to have_http_status(404)
    end
  end

  describe "POST /tasks" do
    it "creates a task with the expected JSON fields" do
      expect {
        post api_v1_tasks_path, params: { task: { title: "Task title", starts_at: Time.now, user_id: @user.id } }
      }.to change { Task.count }.by(1)

      expect(response).to have_http_status(201)
      expect(response).to match_json_schema("task")
    end

    it "does not create a task with invalid parameters" do
      expect {
        post api_v1_tasks_path, params: { task: { title: nil, starts_at: nil, user_id: nil } }
      }.not_to change { Task.count }

      expect(response).to have_http_status(422)

      body = JSON.parse(response.body)
      expect(body["errors"]).to include(
        "Title can't be blank",
        "Starts at can't be blank",
        "User must exist"
      )
    end
  end

  describe "PUT /tasks/:id" do
    it "updates a task with the expected JSON fields" do
      put api_v1_task_path(@task), params: { task: { title: "Updated task title", active: false } }

      expect(response).to have_http_status(200)
      expect(response).to match_json_schema("task")

      @task.reload
      expect(@task.title).to eq("Updated task title")
      expect(@task.active).to eq(false)
    end

    it "does not update a task with invalid parameters" do
      original_attributes = @task.attributes

      put api_v1_task_path(@task), params: { task: { title: nil, active: nil } }

      expect(response).to have_http_status(422)

      body = JSON.parse(response.body)
      expect(body["errors"]).to include(
        "Title can't be blank",
        "Active is not included in the list"
      )

      @task.reload
      expect(@task.attributes).to eq(original_attributes)
    end

    it "returns a 404 if the task does not exist" do
      put api_v1_task_path(0)

      expect(response).to have_http_status(404)
    end
  end
end
