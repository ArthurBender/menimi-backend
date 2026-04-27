require "json"
require "net/http"

module Ai
  class WelcomeMessageService
    class GenerationError < StandardError; end

    DEFAULT_MODEL = "gemini-2.5-flash".freeze

    def self.call(user:, language: nil, reference_time: Time.current)
      new(user:, language:, reference_time:).call
    end

    def initialize(user:, language:, reference_time:)
      @user = user
      @language_override = language
      @reference_time = reference_time
    end

    def call
      Rails.cache.fetch(cache_key, expires_in: 30.hours) do
        generate_message
      end
    end

    private

    attr_reader :language_override, :reference_time, :user

    def api_key
      ENV.fetch("GEMINI_API_KEY")
    rescue KeyError
      raise GenerationError, "GEMINI_API_KEY is not configured"
    end

    def cache_key
      "users/#{user.id}/welcome_message/#{local_date}/#{effective_language}"
    end

    def effective_language
      language_override || user.language
    end

    def daily_resume
      @daily_resume ||= DailyResumeBuilder.call(user:, reference_time:)
    end

    def endpoint
      URI("https://generativelanguage.googleapis.com/v1beta/models/#{model}:generateContent?key=#{api_key}")
    end

    def generate_message
      response = Net::HTTP.start(endpoint.host, endpoint.port, use_ssl: true) do |http|
        http.request(request)
      end

      raise GenerationError, "Gemini request failed with status #{response.code}" unless response.is_a?(Net::HTTPSuccess)

      parse_message(response.body)
    rescue SocketError, Timeout::Error, Errno::ECONNREFUSED, Net::OpenTimeout, Net::ReadTimeout => e
      raise GenerationError, "Gemini request failed: #{e.message}"
    end

    def local_date
      reference_time.in_time_zone(user.timezone).to_date
    end

    def model
      ENV.fetch("GEMINI_MODEL", DEFAULT_MODEL)
    end

    def parse_message(response_body)
      body = JSON.parse(response_body)
      text = body.dig("candidates", 0, "content", "parts", 0, "text")&.strip

      raise GenerationError, "Gemini response did not include a message" if text.blank?

      text
    rescue JSON::ParserError => e
      raise GenerationError, "Gemini response was invalid JSON: #{e.message}"
    end

    def prompt
      <<~PROMPT
        Write a short, warm welcome message for the user's day.
        Keep it under 90 words.
        Mention the user's first name naturally.
        Base the message only on the provided daily resume.
        Do not invent tasks or facts.
        Write the final answer in #{language_label}.

        Daily resume:
        #{JSON.pretty_generate(daily_resume)}
      PROMPT
    end

    def language_label
      effective_language == "pt-BR" ? "Brazilian Portuguese" : "English"
    end

    def request
      Net::HTTP::Post.new(endpoint).tap do |req|
        req["Content-Type"] = "application/json"
        req.body = {
          contents: [
            {
              parts: [
                { text: prompt }
              ]
            }
          ]
        }.to_json
      end
    end
  end
end
