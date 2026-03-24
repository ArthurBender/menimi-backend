class User < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher

  enum :language, {
    en: "en",
    "pt-BR": "pt-BR"
  }, validate: true

  devise :database_authenticatable,
         :registerable,
         :validatable,
         :jwt_authenticatable,
         jwt_revocation_strategy: self

  has_many :tasks, dependent: :destroy
  has_many :push_subscriptions, dependent: :destroy

  validates :email, presence: true, uniqueness: true
  validates :first_name, :language, :last_name, :timezone, presence: true

  before_validation :ensure_jti, on: :create

  def self.jwt_revoked?(payload, user)
    user.jti != payload["jti"]
  end

  def self.revoke_jwt(_payload, user)
    user.update!(jti: SecureRandom.uuid)
  end

  def locale
    language == "pt-BR" ? :"pt-BR" : :en
  end

  private

  def ensure_jti
    self.jti ||= SecureRandom.uuid
  end
end
