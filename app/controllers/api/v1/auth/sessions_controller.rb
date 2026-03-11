module Api
  module V1
    module Auth
      class SessionsController < Devise::SessionsController
        skip_before_action :authenticate_user!
        skip_before_action :verify_signed_out_user, only: :destroy
        respond_to :json

        def create
          self.resource = warden.authenticate!(auth_options)
          sign_in(resource_name, resource, store: false)

          render json: {
            user: {
              id: resource.id,
              email: resource.email,
              first_name: resource.first_name,
              last_name: resource.last_name,
              timezone: resource.timezone
            }
          }, status: :ok
        end

        def destroy
          sign_out(resource_name)
          head :no_content
        end

        private

        def respond_to_on_destroy(non_navigational_status: :no_content)
          head non_navigational_status
        end
      end
    end
  end
end
