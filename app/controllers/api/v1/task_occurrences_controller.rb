module Api
  module V1
    class TaskOccurrencesController < ApplicationController
      before_action :set_task_occurrence, only: %i[update destroy]

      def create
        @task_occurrence = TaskOccurrence.new(task_occurrence_params)

        if @task_occurrence.save
          render :show, status: :created
        else
          render json: { errors: @task_occurrence.errors.full_messages },
                 status: :unprocessable_entity
        end
      end

      def update
        if @task_occurrence.update(task_occurrence_params)
          render :show
        else
          render json: { errors: @task_occurrence.errors.full_messages },
                 status: :unprocessable_entity
        end
      end

      def destroy
        @task_occurrence.destroy
        head :no_content
      end

      private

      def set_task_occurrence
        @task_occurrence = TaskOccurrence.find(params[:id])
      end

      def task_occurrence_params
        params.require(:task_occurrence).permit(:task_id, :occurred_at, :status)
      end
    end
  end
end
