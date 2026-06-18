require "test_helper"

class AliroConfigTest < ActiveSupport::TestCase
  GID         = "17cb8ab0dcd640f3a03cfa2aae7a5775".freeze
  PUB         = "0418e0ba2eef5406549f7ece418ab14af261585de89c141bed7411a9a0f4be1e4cdd6718002dd6163b75e959cb89548a959380d341040e0adf3f557384337b6e89".freeze
  KASTLE_PUB  = "0477f673d22eb6fa831d8c47e82004a2a85202276df1f12ee4fbe42f9e136265c65fa430afcd377ac3e3688c59d8696f783affb6df337de9fb25a0ece77123c017".freeze
  KASTLE_CERT = "3081b2040200003081ab820d3235313230313030303030305a830d3236303630313030303030305a8542000477f673d22eb6fa831d8c47e82004a2a85202276df1f12ee4fbe42f9e136265c65fa430afcd377ac3e3688c59d8696f783affb6df337de9fb25a0ece77123c017864700304402200359ac1c198d818b4cee4e1313711abf4e246339666f8897ea642c42f869153b022023e7d8d583f7f6564aa1393a15742d318e7fe8ff310160acea75c7dbf0e86542".freeze

  def build_config(attrs = {})
    AliroConfig.new({ created_by: users(:alice), name: "Reader", domain_name: "allegion.com",
                      reader_group_id: GID, reader_public_key: PUB }.merge(attrs))
  end

  test "valid with hex inputs; resolves/creates the domain on save" do
    config = build_config
    assert config.valid?, config.errors.full_messages.to_sentence
    config.save!
    assert_equal "allegion.com", config.domain.name
    assert_equal GID, config.reader_group_id
  end

  test "normalizes base64 key material to hex" do
    config = build_config(
      reader_group_id: "f7yuSmdgTPS2D9EMRF0fDQ==",
      reader_public_key: "BAcm4a8s66v1R5nUUtgwtuKs6eIYbBIo1RpXNmNWtK3NUT/GK4yQdeJ4KJr3/3wK7oixvUTi+OUQ8i5mMtPypk0="
    )
    assert config.valid?, config.errors.full_messages.to_sentence
    assert_equal "7fbcae4a67604cf4b60fd10c445d1f0d", config.reader_group_id
  end

  test "rejects a group id that is not 16 bytes" do
    refute build_config(reader_group_id: "abcd").valid?
  end

  test "rejects a public key that is not on the P-256 curve" do
    refute build_config(reader_public_key: PUB[0...-1] + "8").valid?
  end

  test "accepts a certificate that embeds the public key" do
    assert build_config(reader_public_key: KASTLE_PUB, reader_certificate: KASTLE_CERT).valid?
  end

  test "rejects a certificate that does not embed the public key" do
    refute build_config(reader_public_key: PUB, reader_certificate: KASTLE_CERT).valid?
  end

  test "rejects an invalid domain name" do
    refute build_config(domain_name: "notadomain").valid?
  end

  test "requires a name" do
    refute build_config(name: "").valid?
  end
end
