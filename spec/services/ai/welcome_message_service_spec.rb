require "rails_helper"

RSpec.describe Ai::WelcomeMessageService do
  around do |example|
    original_cache = Rails.cache
    temp_cache = ActiveSupport::Cache.lookup_store(:memory_store)

    Rails.cache = temp_cache

    example.run
  ensure
    temp_cache&.clear
    Rails.cache = original_cache
  end

  describe ".call" do
    let(:timezone) { "America/Sao_Paulo" }
    let(:user) { create(:user, timezone:, first_name: "Jane", last_name: "Doe") }
    let(:response_body) do
      {
        candidates: [
          {
            content: {
              parts: [
                { text: "Good morning, Jane. You have 2 tasks to focus on today." }
              ]
            }
          }
        ]
      }.to_json
    end
    let(:http_response) { instance_double(Net::HTTPSuccess, body: response_body, code: "200") }
    let(:http_client) { instance_double(Net::HTTP) }

    before do
      create(
        :task,
        user:,
        title: "Review roadmap",
        starts_at: Time.use_zone(timezone) { Time.zone.parse("2026-03-24 09:00:00") }
      )

      allow(Net::HTTP).to receive(:start).and_yield(http_client)
      allow(http_client).to receive(:request).and_return(http_response)
      allow(http_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with("GEMINI_API_KEY").and_return("test-api-key")
      allow(ENV).to receive(:fetch).with("GEMINI_MODEL", described_class::DEFAULT_MODEL)
                                 .and_return(described_class::DEFAULT_MODEL)
    end

    it "caches the generated message for the same user and local day" do
      reference_time = Time.use_zone(timezone) { Time.zone.parse("2026-03-24 08:00:00") }

      first_message = described_class.call(user:, reference_time:)
      second_message = described_class.call(user:, reference_time: reference_time + 2.hours)

      expect(first_message).to eq("Good morning, Jane. You have 2 tasks to focus on today.")
      expect(second_message).to eq(first_message)
      expect(http_client).to have_received(:request).once
    end

    it "generates a new message when the user's local day changes" do
      first_time = Time.use_zone(timezone) { Time.zone.parse("2026-03-24 23:30:00") }
      second_time = Time.use_zone(timezone) { Time.zone.parse("2026-03-25 00:10:00") }

      described_class.call(user:, reference_time: first_time)
      described_class.call(user:, reference_time: second_time)

      expect(http_client).to have_received(:request).twice
    end

    it "raises a generation error when the API key is missing" do
      allow(ENV).to receive(:fetch).with("GEMINI_API_KEY").and_raise(KeyError)

      expect do
        described_class.call(user:)
      end.to raise_error(described_class::GenerationError, "GEMINI_API_KEY is not configured")
    end

    it "instructs Gemini to answer in the user's preferred language" do
      user.update!(language: "pt-BR")
      captured_request = nil

      allow(http_client).to receive(:request) do |request|
        captured_request = request
        http_response
      end

      described_class.call(user:)

      request_payload = JSON.parse(captured_request.body)
      prompt = request_payload.dig("contents", 0, "parts", 0, "text")

      expect(prompt).to include("Write the final answer in Brazilian Portuguese.")
      expect(prompt).to include("\"language\": \"pt-BR\"")
    end
  end
end
