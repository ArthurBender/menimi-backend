require "rails_helper"

RSpec.describe "Auth", type: :request do
  describe "POST /api/v1/auth/signup" do
    it "creates an account" do
      expect do
        post "/api/v1/auth/signup", params: {
          user: {
            email: "new-user@example.com",
            password: "password123",
            password_confirmation: "password123",
            first_name: "Jane",
            last_name: "Doe",
            language: "pt-BR",
            timezone: "America/Sao_Paulo"
          }
        }
      end.to change(User, :count).by(1)

      expect(response).to have_http_status(:created)

      body = JSON.parse(response.body)
      expect(body.dig("user", "email")).to eq("new-user@example.com")
      expect(body.dig("user", "language")).to eq("pt-BR")
    end

    it "returns validation errors" do
      post "/api/v1/auth/signup", params: {
        user: {
          email: "bad-email",
          password: "short",
          password_confirmation: "mismatch",
          first_name: nil,
          language: nil,
          last_name: nil,
          timezone: nil
        }
      }

      expect(response).to have_http_status(:unprocessable_content)

      body = JSON.parse(response.body)
      expect(body["errors"]).to include(
        "Email is invalid",
        "Password confirmation doesn't match Password",
        "Password is too short (minimum is 8 characters)",
        "First name can't be blank",
        "Language can't be blank",
        "Last name can't be blank",
        "Timezone can't be blank"
      )
    end
  end

  describe "POST /api/v1/auth/login" do
    before do
      create(
        :user,
        email: "user@example.com",
        language: "pt-BR",
        password: "password123",
        password_confirmation: "password123"
      )
    end

    it "returns a jwt authorization header" do
      post "/api/v1/auth/login", params: {
        user: {
          email: "user@example.com",
          password: "password123"
        }
      }

      expect(response).to have_http_status(:ok)
      expect(response.headers["Authorization"]).to start_with("Bearer ")
      expect(JSON.parse(response.body).dig("user", "language")).to eq("pt-BR")
    end

    it "rejects invalid credentials" do
      post "/api/v1/auth/login", params: {
        user: {
          email: "user@example.com",
          password: "wrong-password"
        }
      }

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "PATCH /api/v1/auth/account" do
    it "updates the signed-in account without current password" do
      user = create(:user, password: "password123", password_confirmation: "password123")

      patch "/api/v1/auth/account",
            params: { user: { first_name: "Updated", language: "pt-BR", timezone: "America/New_York" } }.to_json,
            headers: auth_headers_for(user)

      expect(response).to have_http_status(:ok)

      user.reload
      expect(user.first_name).to eq("Updated")
      expect(user.language).to eq("pt-BR")
      expect(user.timezone).to eq("America/New_York")
    end

    it "requires authentication" do
      patch "/api/v1/auth/account", params: { user: { first_name: "Updated" } }

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
