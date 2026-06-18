class User < ApplicationRecord
  # Passwordless magic-link login + short-lived sessions (timeoutable).
  devise :magic_link_authenticatable, :timeoutable

  before_validation { self.email = email.to_s.strip.downcase.presence }

  validates :email, presence: true, uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP, message: "is not a valid email address" }
  validate :email_must_be_organizational

  def email_domain
    email.to_s.split("@").last
  end

  private

  # Org-email-only: reject free-mail providers so account access tracks
  # employment (lose the mailbox -> lose access).
  def email_must_be_organizational
    return if email.blank?

    if FreeEmailDomains.include?(email_domain)
      errors.add(:email, "must be your organization email address (free-mail providers aren't allowed)")
    end
  end
end
