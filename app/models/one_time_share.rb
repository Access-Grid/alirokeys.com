class OneTimeShare < ApplicationRecord
  # aliro_config is nulled when the share is consumed (the config is destroyed).
  belongs_to :aliro_config, optional: true
  has_secure_password :secret, validations: false

  validates :token, presence: true, uniqueness: true

  # Create a share for a config; returns [share, plaintext_secret].
  # The secret is shown to the creator once and only stored as a bcrypt digest.
  def self.mint!(config:, ttl: 24.hours)
    secret = generate_secret
    share = create!(
      aliro_config: config,
      secret: secret,
      token: generate_token,
      expires_at: ttl.from_now
    )
    [ share, secret ]
  end

  def self.generate_token = SecureRandom.urlsafe_base64(16)

  def self.generate_secret
    SecureRandom.alphanumeric(16).downcase.scan(/.{4}/).join("-")
  end

  def retrievable?
    retrieved_at.nil? && aliro_config_id.present? && expires_at&.future?
  end

  # Atomically claim this share so it can only be consumed once (race-safe even
  # under concurrent requests). Returns true if this caller won the claim.
  def claim!
    OneTimeShare.where(id: id, retrieved_at: nil).update_all(retrieved_at: Time.current).positive?
  end
end
