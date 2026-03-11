module Api
  module V1
    module Auth
      class SessionsController < Devise::SessionsController
        skip_before_action :authenticate_user!
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

        def respond_to_on_destroy
          head :no_content
        end
      end
    end
  end
end
