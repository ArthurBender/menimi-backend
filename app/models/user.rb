class User < ApplicationRecord
  has_many :tasks, dependent: :destroy

  validates :email, presence: true, uniqueness: true
  validates :first_name, :last_name, :timezone, presence: true
end
