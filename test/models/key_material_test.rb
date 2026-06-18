require "test_helper"
require "base64"

class KeyMaterialTest < ActiveSupport::TestCase
  GID  = "17cb8ab0dcd640f3a03cfa2aae7a5775".freeze
  PUB  = "0418e0ba2eef5406549f7ece418ab14af261585de89c141bed7411a9a0f4be1e4cdd6718002dd6163b75e959cb89548a959380d341040e0adf3f557384337b6e89".freeze
  KASTLE_PUB  = "0477f673d22eb6fa831d8c47e82004a2a85202276df1f12ee4fbe42f9e136265c65fa430afcd377ac3e3688c59d8696f783affb6df337de9fb25a0ece77123c017".freeze
  KASTLE_CERT = "3081b2040200003081ab820d3235313230313030303030305a830d3236303630313030303030305a8542000477f673d22eb6fa831d8c47e82004a2a85202276df1f12ee4fbe42f9e136265c65fa430afcd377ac3e3688c59d8696f783affb6df337de9fb25a0ece77123c017864700304402200359ac1c198d818b4cee4e1313711abf4e246339666f8897ea642c42f869153b022023e7d8d583f7f6564aa1393a15742d318e7fe8ff310160acea75c7dbf0e86542".freeze

  test "decodes hex with optional 0x prefix and whitespace" do
    raw = [ GID ].pack("H*")
    assert_equal raw, KeyMaterial.to_bytes(GID)
    assert_equal raw, KeyMaterial.to_bytes("0x#{GID}")
    assert_equal raw, KeyMaterial.to_bytes("17cb 8ab0 dcd6 40f3 a03c fa2a ae7a 5775")
  end

  test "decodes base64" do
    raw = [ GID ].pack("H*")
    assert_equal raw, KeyMaterial.to_bytes(Base64.strict_encode64(raw))
  end

  test "returns nil for undecodable input" do
    assert_nil KeyMaterial.to_bytes("not hex or base64 !!!")
    assert_nil KeyMaterial.to_bytes("")
  end

  test "normalize_hex returns lowercase hex" do
    assert_equal GID, KeyMaterial.normalize_hex(GID.upcase)
  end

  test "group_id? requires 16 bytes" do
    assert KeyMaterial.group_id?(KeyMaterial.to_bytes(GID))
    assert_not KeyMaterial.group_id?(KeyMaterial.to_bytes("abcd"))
  end

  test "on_curve? validates real P-256 points" do
    assert KeyMaterial.on_curve?(KeyMaterial.to_bytes(PUB))
    assert_not KeyMaterial.on_curve?(KeyMaterial.to_bytes(PUB[0...-1] + "8")) # flipped -> off curve
    assert_not KeyMaterial.on_curve?(KeyMaterial.to_bytes("04abcd"))          # wrong length
  end

  test "cert_embeds_key? checks the embedded public key" do
    cert = KeyMaterial.to_bytes(KASTLE_CERT)
    assert KeyMaterial.cert_embeds_key?(cert, KeyMaterial.to_bytes(KASTLE_PUB))
    assert_not KeyMaterial.cert_embeds_key?(cert, KeyMaterial.to_bytes(PUB))
  end
end
