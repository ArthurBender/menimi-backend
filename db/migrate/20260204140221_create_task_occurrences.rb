class CreateTaskOccurrences < ActiveRecord::Migration[8.1]
  def change
    create_table :task_occurrences do |t|
      t.references :task, null: false, foreign_key: true
      t.datetime :occurred_at, null: false
      t.string :status, null: false

      t.timestamps
    end

    add_index :task_occurrences, %i[task_id occurred_at]
  end
end
