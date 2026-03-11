module Api
  module V1
    module Auth
      class BaseController < ApplicationController
        private

        def render_resource(resource, status: :ok)
          render json: {
            user: {
              id: resource.id,
              email: resource.email,
              first_name: resource.first_name,
              last_name: resource.last_name,
              timezone: resource.timezone
            }
          }, status: status
        end

        def render_errors(resource, status: :unprocessable_entity)
          render json: { errors: resource.errors.full_messages }, status: status
        end
      end
    end
  end
end
