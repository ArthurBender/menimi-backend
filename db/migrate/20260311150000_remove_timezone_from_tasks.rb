class RemoveTimezoneFromTasks < ActiveRecord::Migration[8.1]
  def change
    remove_column :tasks, :timezone, :string
  end
end
