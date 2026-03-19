class PushSubscription < ApplicationRecord
  belongs_to :user

  validates :endpoint, :auth_key, :p256dh_key, presence: true
  validates :endpoint, uniqueness: true
end
