module Api
  module V1
    class TasksController < ApplicationController
      before_action :set_task, only: %i[show update]

      def index
        @tasks = current_user.tasks.includes(:task_occurrences)
      end

      def show; end

      def create
        @task = current_user.tasks.new(task_params)

        if @task.save
          render :show, status: :created
        else
          render json: { errors: @task.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        if @task.update(task_params)
          render :show
        else
          render json: { errors: @task.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def set_task
        @task = current_user.tasks.includes(:task_occurrences).find(params[:id])
      end

      def task_params
        params.require(:task).permit(
          :title,
          :description,
          :rrule,
          :starts_at,
          :carry_over,
          :active
        )
      end
    end
  end
end
