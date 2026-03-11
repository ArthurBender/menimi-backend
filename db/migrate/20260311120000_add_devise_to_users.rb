class AddDeviseToUsers < ActiveRecord::Migration[8.1]
  def change
    User.destroy_all

    change_table :users, bulk: true do |t|
      t.string :encrypted_password, null: false
      t.string :jti, null: false
    end

    add_index :users, :jti, unique: true
  end
end
