module Api
  module V1
    class PushSubscriptionsController < ApplicationController
      def create
        push_subscription = PushSubscription.find_or_initialize_by(endpoint: subscription_params[:endpoint])
        status = push_subscription.new_record? ? :created : :ok

        if push_subscription.update(create_params)
          render json: {}, status: status
        else
          render json: { errors: push_subscription.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        current_user.push_subscriptions.find_by(endpoint: destroy_params[:endpoint])&.destroy
        head :no_content
      end

      private

      def create_params
        {
          user: current_user,
          endpoint: subscription_params[:endpoint],
          expiration_time: subscription_params[:expirationTime],
          auth_key: subscription_keys_params[:auth],
          p256dh_key: subscription_keys_params[:p256dh],
          user_agent: request.user_agent
        }
      end

      def subscription_params
        params.require(:subscription).permit(:endpoint, :expirationTime, keys: %i[auth p256dh])
      end

      def subscription_keys_params
        subscription_params.require(:keys)
      end

      def destroy_params
        params.permit(:endpoint)
      end
    end
  end
end
