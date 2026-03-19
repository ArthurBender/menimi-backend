require "rails_helper"

RSpec.describe "PushSubscriptions", type: :request do
  describe "POST /api/v1/push_subscriptions" do
    it "creates a push subscription for the current user" do
      user = create(:user)

      expect do
        post api_v1_push_subscriptions_path,
             params: {
               subscription: {
                 endpoint: "https://push.example.test/subscriptions/subscription-1",
                 expirationTime: 1_710_000_000,
                 keys: {
                   auth: "auth-key",
                   p256dh: "p256dh-key"
                 }
               }
             }.to_json,
             headers: auth_headers_for(user).merge("User-Agent" => "Menimi Web")
      end.to change(PushSubscription, :count).by(1)

      expect(response).to have_http_status(:created)

      subscription = PushSubscription.last
      expect(subscription.user).to eq(user)
      expect(subscription.endpoint).to eq("https://push.example.test/subscriptions/subscription-1")
      expect(subscription.expiration_time).to eq(1_710_000_000)
      expect(subscription.auth_key).to eq("auth-key")
      expect(subscription.p256dh_key).to eq("p256dh-key")
      expect(subscription.user_agent).to eq("Menimi Web")
      expect(JSON.parse(response.body)).to eq({})
    end

    it "updates an existing push subscription by endpoint" do
      original_user = create(:user)
      current_user = create(:user)
      subscription = create(
        :push_subscription,
        user: original_user,
        endpoint: "https://push.example.test/subscriptions/subscription-1",
        auth_key: "old-auth-key",
        p256dh_key: "old-p256dh-key",
        expiration_time: nil
      )

      expect do
        post api_v1_push_subscriptions_path,
             params: {
               subscription: {
                 endpoint: subscription.endpoint,
                 expirationTime: 1_720_000_000,
                 keys: {
                   auth: "new-auth-key",
                   p256dh: "new-p256dh-key"
                 }
               }
             }.to_json,
             headers: auth_headers_for(current_user).merge("User-Agent" => "Updated Agent")
      end.not_to change(PushSubscription, :count)

      expect(response).to have_http_status(:ok)

      subscription.reload
      expect(subscription.user).to eq(current_user)
      expect(subscription.expiration_time).to eq(1_720_000_000)
      expect(subscription.auth_key).to eq("new-auth-key")
      expect(subscription.p256dh_key).to eq("new-p256dh-key")
      expect(subscription.user_agent).to eq("Updated Agent")
    end

    it "requires authentication" do
      post api_v1_push_subscriptions_path,
           params: {
             subscription: {
               endpoint: "https://push.example.test/subscriptions/subscription-1",
               expirationTime: nil,
               keys: {
                 auth: "auth-key",
                 p256dh: "p256dh-key"
               }
             }
           }.to_json

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "DELETE /api/v1/push_subscriptions" do
    it "deletes the current user's push subscription by endpoint" do
      user = create(:user)
      push_subscription = create(:push_subscription, user: user)

      expect do
        delete api_v1_push_subscriptions_path,
               params: { endpoint: push_subscription.endpoint }.to_json,
               headers: auth_headers_for(user)
      end.to change(PushSubscription, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end

    it "does not delete another user's push subscription" do
      current_user = create(:user)
      other_subscription = create(:push_subscription)

      expect do
        delete api_v1_push_subscriptions_path,
               params: { endpoint: other_subscription.endpoint }.to_json,
               headers: auth_headers_for(current_user)
      end.not_to change(PushSubscription, :count)

      expect(response).to have_http_status(:no_content)
      expect(other_subscription.reload).to be_present
    end

    it "requires authentication" do
      delete api_v1_push_subscriptions_path, params: { endpoint: "https://push.example.com/subscriptions/1" }.to_json

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
