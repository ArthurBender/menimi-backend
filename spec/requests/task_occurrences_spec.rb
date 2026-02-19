require 'rails_helper'

RSpec.describe "TaskOccurrences", type: :request do
  before do
    @user = create(:user)
    @task = create(:task, user: @user)
    @task_occurrence = create(:task_occurrence, task: @task)
  end

  describe "POST /task_occurrences" do
    it "creates a task_occurrence with the expected JSON fields" do
      expect {
        post api_v1_task_occurrences_path, params: { task_occurrence: { task_id: @task.id, occurred_at: Time.now, status: "done" } }
      }.to change { TaskOccurrence.count }.by(1)

      expect(response).to have_http_status(201)
      expect(response).to match_json_schema("task_occurrence")
    end

    it "does not create a task_occurrence with invalid parameters" do
      expect {
        post api_v1_task_occurrences_path, params: { task_occurrence: { task_id: nil, occurred_at: nil, status: nil } }
      }.to change { TaskOccurrence.count }.by(0)

      expect(response).to have_http_status(422)

      body = JSON.parse(response.body)
      expect(body["errors"]).to include(
        "Task must exist",
        "Occurred at can't be blank",
        "Status can't be blank"
      )
    end
  end

  describe "PUT /task_occurrences/:id" do
    it "updates a task_occurrence with the expected JSON fields" do
      put api_v1_task_occurrence_path(@task_occurrence), params: { task_occurrence: { status: "missed" } }

      expect(response).to have_http_status(200)
      expect(response).to match_json_schema("task_occurrence")

      @task_occurrence.reload
      expect(@task_occurrence.status).to eq("missed")
    end

    it "does not update a task_occurrence with invalid parameters" do
      put api_v1_task_occurrence_path(@task_occurrence), params: { task_occurrence: { status: nil } }

      expect(response).to have_http_status(422)

      body = JSON.parse(response.body)
      expect(body["errors"]).to include("Status can't be blank")
    end

    it "returns a 404 if the task_occurrence does not exist" do
      put api_v1_task_occurrence_path(0)

      expect(response).to have_http_status(404)
    end
  end

  describe "DELETE /task_occurrences/:id" do
    it "deletes a task_occurrence" do
      expect {
        delete api_v1_task_occurrence_path(@task_occurrence)
      }.to change { TaskOccurrence.count }.by(-1)

      expect(response).to have_http_status(204)
    end

    it "returns a 404 if the task_occurrence does not exist" do
      delete api_v1_task_occurrence_path(0)

      expect(response).to have_http_status(404)
    end
  end
end
