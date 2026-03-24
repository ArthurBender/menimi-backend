module Api
  module V1
    class WelcomeMessagesController < ApplicationController
      def show
        message = Ai::WelcomeMessageService.call(user: current_user)

        render json: { message: }
      rescue Ai::WelcomeMessageService::GenerationError => e
        render json: { error: e.message }, status: :service_unavailable
      end
    end
  end
end
