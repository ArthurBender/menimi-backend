class CreateTasks < ActiveRecord::Migration[8.1]
  def change
    create_table :tasks do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false
      t.text :description
      t.string :rrule
      t.datetime :starts_at, null: false
      t.string :timezone, null: false
      t.boolean :carry_over, null: false, default: false
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :tasks, :active
  end
end
