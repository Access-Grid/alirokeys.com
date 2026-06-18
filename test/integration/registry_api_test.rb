require "test_helper"

class RegistryApiTest < ActionDispatch::IntegrationTest
  GID         = "17cb8ab0dcd640f3a03cfa2aae7a5775".freeze
  PUB         = "0418e0ba2eef5406549f7ece418ab14af261585de89c141bed7411a9a0f4be1e4cdd6718002dd6163b75e959cb89548a959380d341040e0adf3f557384337b6e89".freeze
  KASTLE_PUB  = "0477f673d22eb6fa831d8c47e82004a2a85202276df1f12ee4fbe42f9e136265c65fa430afcd377ac3e3688c59d8696f783affb6df337de9fb25a0ece77123c017".freeze
  KASTLE_CERT = "3081b2040200003081ab820d3235313230313030303030305a830d3236303630313030303030305a8542000477f673d22eb6fa831d8c47e82004a2a85202276df1f12ee4fbe42f9e136265c65fa430afcd377ac3e3688c59d8696f783affb6df337de9fb25a0ece77123c017864700304402200359ac1c198d818b4cee4e1313711abf4e246339666f8897ea642c42f869153b022023e7d8d583f7f6564aa1393a15742d318e7fe8ff310160acea75c7dbf0e86542".freeze

  setup do
    @domain = Domain.create!(name: "acme.dev")
    @domain.aliro_configs.create!(created_by: users(:alice), name: "Door",
      reader_group_id: GID, reader_public_key: PUB, is_sample: true)
    @domain.aliro_configs.create!(created_by: users(:alice), name: "Cert",
      reader_group_id: GID, reader_public_key: KASTLE_PUB, reader_certificate: KASTLE_CERT, is_sample: true)
    @domain.aliro_configs.create!(created_by: users(:alice), name: "Private",
      reader_group_id: GID, reader_public_key: PUB, is_sample: false)
  end

  test "aliro.json lists only sample configs, with hex + base64, and never a creator email" do
    get domain_aliro_path("acme.dev")
    assert_response :success
    assert_equal "application/json", response.media_type

    body = JSON.parse(response.body)
    assert_equal "acme.dev", body["domain"]
    assert_equal %w[Cert Door], body["configs"].map { |c| c["name"] }

    door = body["configs"].find { |c| c["name"] == "Door" }
    assert_equal GID, door["reader_group_id"]
    assert door["reader_group_id_base64"].present?
    assert door["reader_public_key_base64"].present?
    assert_nil door["reader_certificate"]

    cert = body["configs"].find { |c| c["name"] == "Cert" }
    assert_equal KASTLE_CERT, cert["reader_certificate"]
    assert cert["reader_certificate_base64"].present?

    refute response.body.include?("alice@"), "creator email must never appear in the API"
    refute door.key?("created_by")
  end

  test "api/v1/domains endpoint returns the same payload" do
    get api_domain_path("acme.dev")
    assert_response :success
    assert_equal %w[Cert Door], JSON.parse(response.body)["configs"].map { |c| c["name"] }
  end

  test "unknown domain returns an empty config list" do
    get domain_aliro_path("nope.dev")
    assert_response :success
    assert_equal [], JSON.parse(response.body)["configs"]
  end
end
