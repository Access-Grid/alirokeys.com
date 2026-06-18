class AliroConfig < ApplicationRecord
  belongs_to :domain, optional: true # resolved from domain_name before save
  belongs_to :created_by, class_name: "User"

  attr_writer :domain_name

  before_validation :normalize_key_material
  before_save :resolve_domain

  validates :name, presence: true
  validate  :domain_name_is_valid
  validate  :reader_group_id_is_valid
  validate  :reader_public_key_is_valid
  validate  :reader_certificate_is_valid

  scope :samples, -> { where(is_sample: true) }

  # Presentation interface (shared with views / CodeExporter). Stored as hex.
  def domain_name
    @domain_name&.strip&.downcase.presence || domain&.name
  end

  def cert? = reader_certificate.present?

  private

  def normalize_key_material
    %i[reader_group_id reader_public_key reader_certificate].each do |attr|
      value = self[attr]
      next if value.blank?

      hex = KeyMaterial.normalize_hex(value)
      self[attr] = hex if hex # leave raw input for the validator to flag otherwise
    end
  end

  def resolve_domain
    self.domain ||= Domain.find_or_create_by(name: domain_name) if domain_name.present?
  end

  def domain_name_is_valid
    if domain_name.blank?
      errors.add(:domain_name, "can't be blank")
    elsif !domain_name.match?(Domain::NAME_FORMAT)
      errors.add(:domain_name, "is not a valid domain")
    end
  end

  def reader_group_id_is_valid
    return if reader_group_id.blank?

    unless KeyMaterial.group_id?(KeyMaterial.to_bytes(reader_group_id))
      errors.add(:reader_group_id, "must be 16 bytes (hex or base64)")
    end
  end

  def reader_public_key_is_valid
    return if reader_public_key.blank?

    unless KeyMaterial.on_curve?(KeyMaterial.to_bytes(reader_public_key))
      errors.add(:reader_public_key, "must be a 65-byte uncompressed P-256 point on the curve")
    end
  end

  def reader_certificate_is_valid
    return if reader_certificate.blank?

    cert = KeyMaterial.to_bytes(reader_certificate)
    pubkey = KeyMaterial.to_bytes(reader_public_key)
    unless KeyMaterial.cert_embeds_key?(cert, pubkey)
      errors.add(:reader_certificate, "is not a valid reader certificate embedding this public key")
    end
  end
end
