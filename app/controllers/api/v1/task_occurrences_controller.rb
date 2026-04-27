module Api
  module V1
    class TaskOccurrencesController < ApplicationController
      before_action :set_task_occurrence, only: %i[update destroy]

      def stats
        occurrences = TaskOccurrence.joins(:task).where(tasks: { user_id: current_user.id })
        render json: {
          done: occurrences.status_done.count,
          missed: occurrences.status_missed.count
        }
      end

      def create
        if resolve_missed_occurrence!
          render :show
          return
        end

        @task_occurrence = TaskOccurrence.new(create_task_occurrence_params)

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
        @task_occurrence = TaskOccurrence.joins(:task)
                                         .where(tasks: { user_id: current_user.id })
                                         .find(params[:id])
      end

      def task_occurrence_params
        permitted_params = params.require(:task_occurrence).permit(:task_id, :occurred_at, :status, :carried_from)

        return permitted_params if permitted_params[:task_id].blank?

        permitted_params.merge(task_id: current_user.tasks.find(permitted_params[:task_id]).id)
      end

      def create_task_occurrence_params
        task_occurrence_params.except(:carried_from)
      end

      def resolve_missed_occurrence!
        return false unless task_occurrence_params[:status].to_s == "done"
        return false if task_occurrence_params[:carried_from].blank?

        task = current_user.tasks.find_by(id: task_occurrence_params[:task_id])
        occurred_at = task_occurrence_params[:occurred_at]

        return false if task.blank?

        @task_occurrence = task.task_occurrences.status_missed
                               .find_by(id: task_occurrence_params[:carried_from])
        return false unless @task_occurrence

        @task_occurrence.update!(
          status: :done,
          occurred_at: occurred_at.presence || @task_occurrence.occurred_at
        )
        true
      end
    end
  end
end
