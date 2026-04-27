module Api
  module V1
    class WelcomeMessagesController < ApplicationController
      VALID_LANGUAGES = %w[en pt-BR].freeze

      def show
        language = params[:language].presence
        if language && !VALID_LANGUAGES.include?(language)
          return render json: { error: "language must be 'en' or 'pt-BR'" }, status: :bad_request
        end

        message = Ai::WelcomeMessageService.call(user: current_user, language:)
        render json: { message: }
      rescue Ai::WelcomeMessageService::GenerationError => e
        render json: { error: e.message }, status: :service_unavailable
      end
    end
  end
end
