module Api
  module V1
    module Auth
      class RegistrationsController < BaseController
        skip_before_action :authenticate_user!, only: :create

        def create
          user = User.new(sign_up_params)

          if user.save
            render_resource(user, status: :created)
          else
            render_errors(user)
          end
        end

        def update
          if current_user.update_without_password(account_update_params)
            render_resource(current_user)
          else
            render_errors(current_user)
          end
        end

        private

        def sign_up_params
          params.require(:user).permit(
            :email,
            :password,
            :password_confirmation,
            :first_name,
            :last_name,
            :timezone
          )
        end

        def account_update_params
          params.require(:user).permit(
            :email,
            :password,
            :password_confirmation,
            :first_name,
            :last_name,
            :timezone
          ).compact_blank
        end
      end
    end
  end
end
