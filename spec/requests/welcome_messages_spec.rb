require "rails_helper"

RSpec.describe "WelcomeMessages", type: :request do
  describe "GET /api/v1/welcome_message" do
    it "returns the cached welcome message for the signed-in user" do
      user = create(:user)

      allow(Ai::WelcomeMessageService).to receive(:call).with(user:).and_return("You have a focused day ahead.")

      get api_v1_welcome_message_path, headers: auth_headers_for(user)

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq("message" => "You have a focused day ahead.")
    end

    it "returns a 503 when welcome message generation fails" do
      user = create(:user)

      allow(Ai::WelcomeMessageService).to receive(:call).with(user:).and_raise(
        Ai::WelcomeMessageService::GenerationError, "Gemini request failed"
      )

      get api_v1_welcome_message_path, headers: auth_headers_for(user)

      expect(response).to have_http_status(:service_unavailable)
      expect(JSON.parse(response.body)).to eq("error" => "Gemini request failed")
    end

    it "requires authentication" do
      get api_v1_welcome_message_path

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
