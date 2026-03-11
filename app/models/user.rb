class User < ApplicationRecord
  devise :database_authenticatable,
         :registerable,
         :validatable,
         :jwt_authenticatable,
         jwt_revocation_strategy: self

  has_many :tasks, dependent: :destroy

  validates :email, presence: true, uniqueness: true
  validates :first_name, :last_name, :timezone, presence: true

  before_validation :ensure_jti, on: :create

  def self.jwt_revoked?(payload, user)
    user.jti != payload["jti"]
  end

  def self.revoke_jwt(_payload, user)
    user.update!(jti: SecureRandom.uuid)
  end

  private

  def ensure_jti
    self.jti ||= SecureRandom.uuid
  end
end
