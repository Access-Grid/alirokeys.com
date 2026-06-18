# Static sample data for the Phase 0 production-quality front-end prototype.
#
# No ActiveRecord — plain Ruby objects holding real example values (decoded to
# hex) so the UI renders legitimate Aliro key material. This is replaced by real
# models in Phase 3; the views built against it are kept.
module SampleData
  Config = Struct.new(
    :id, :name, :domain, :reader_group_id, :reader_public_key,
    :reader_certificate, :is_sample, :created_by, :created_at,
    keyword_init: true
  ) do
    def cert? = reader_certificate.present?
    def to_param = id.to_s
  end

  MOCK_USER = "ab@allegion.com".freeze

  CONFIGS = [
    Config.new(
      id: 1, name: "Front Door Reader", domain: "allegion.com",
      reader_group_id: "17cb8ab0dcd640f3a03cfa2aae7a5775",
      reader_public_key: "0418e0ba2eef5406549f7ece418ab14af261585de89c141bed7411a9a0f4be1e4cdd6718002dd6163b75e959cb89548a959380d341040e0adf3f557384337b6e89",
      reader_certificate: nil,
      is_sample: true, created_by: "ab@allegion.com", created_at: "2026-05-02"
    ),
    Config.new(
      id: 2, name: "Parking Garage Reader", domain: "allegion.com",
      reader_group_id: "bcbc8068c73b4a22b52403e5070de64e",
      reader_public_key: "0477f673d22eb6fa831d8c47e82004a2a85202276df1f12ee4fbe42f9e136265c65fa430afcd377ac3e3688c59d8696f783affb6df337de9fb25a0ece77123c017",
      reader_certificate: "3081b2040200003081ab820d3235313230313030303030305a830d3236303630313030303030305a8542000477f673d22eb6fa831d8c47e82004a2a85202276df1f12ee4fbe42f9e136265c65fa430afcd377ac3e3688c59d8696f783affb6df337de9fb25a0ece77123c017864700304402200359ac1c198d818b4cee4e1313711abf4e246339666f8897ea642c42f869153b022023e7d8d583f7f6564aa1393a15742d318e7fe8ff310160acea75c7dbf0e86542",
      is_sample: true, created_by: "security@allegion.com", created_at: "2026-05-10"
    ),
    Config.new(
      id: 3, name: "Staging Door (unlisted)", domain: "allegion.com",
      reader_group_id: "a1b2c3d4e5f60718293a4b5c6d7e8f90",
      reader_public_key: "0418e0ba2eef5406549f7ece418ab14af261585de89c141bed7411a9a0f4be1e4cdd6718002dd6163b75e959cb89548a959380d341040e0adf3f557384337b6e89",
      reader_certificate: nil,
      is_sample: false, created_by: "ab@allegion.com", created_at: "2026-06-01"
    ),
    Config.new(
      id: 4, name: "Pixel Reader Profile", domain: "google.com",
      reader_group_id: "7fbcae4a67604cf4b60fd10c445d1f0d",
      reader_public_key: "040726e1af2cebabf54799d452d830b6e2ace9e2186c1228d51a57366356b4adcd513fc62b8c9075e278289af7ff7c0aee88b1bd44e2f8e510f22e6632d3f2a64d",
      reader_certificate: nil,
      is_sample: true, created_by: "keys@google.com", created_at: "2026-04-18"
    ),
    Config.new(
      id: 5, name: "Elatec Reader (Kastle)", domain: "kastle.com",
      reader_group_id: "bcbc8068c73b4a22b52403e5070de64e",
      reader_public_key: "0477f673d22eb6fa831d8c47e82004a2a85202276df1f12ee4fbe42f9e136265c65fa430afcd377ac3e3688c59d8696f783affb6df337de9fb25a0ece77123c017",
      reader_certificate: "3081b2040200003081ab820d3235313230313030303030305a830d3236303630313030303030305a8542000477f673d22eb6fa831d8c47e82004a2a85202276df1f12ee4fbe42f9e136265c65fa430afcd377ac3e3688c59d8696f783affb6df337de9fb25a0ece77123c017864700304402200359ac1c198d818b4cee4e1313711abf4e246339666f8897ea642c42f869153b022023e7d8d583f7f6564aa1393a15742d318e7fe8ff310160acea75c7dbf0e86542",
      is_sample: true, created_by: "dev@kastle.com", created_at: "2026-03-22"
    )
  ].freeze

  module_function

  def all = CONFIGS

  def domains
    CONFIGS.group_by(&:domain).map do |name, configs|
      { name: name, total: configs.size, samples: configs.count(&:is_sample) }
    end.sort_by { |d| d[:name] }
  end

  def configs_for(domain) = CONFIGS.select { |c| c.domain == domain }

  def sample_configs_for(domain) = configs_for(domain).select(&:is_sample)

  def find(id) = CONFIGS.find { |c| c.id.to_s == id.to_s }

  def for_user(email = MOCK_USER) = CONFIGS.select { |c| c.created_by == email }

  # Representative config used by the one-time share + retrieval mock screens.
  def share_example = find(3)
end
