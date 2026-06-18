require "test_helper"

class DomainTest < ActiveSupport::TestCase
  GID = "17cb8ab0dcd640f3a03cfa2aae7a5775".freeze
  PUB = "0418e0ba2eef5406549f7ece418ab14af261585de89c141bed7411a9a0f4be1e4cdd6718002dd6163b75e959cb89548a959380d341040e0adf3f557384337b6e89".freeze

  test "normalizes name to stripped lowercase" do
    assert_equal "allegion.com", Domain.create!(name: " Allegion.COM ").name
  end

  test "requires a valid, unique name" do
    Domain.create!(name: "allegion.com")
    assert_not Domain.new(name: "allegion.com").valid?
    assert_not Domain.new(name: "nodot").valid?
    assert_not Domain.new(name: "").valid?
  end

  test "sample_configs returns only listed samples" do
    domain = Domain.create!(name: "acme.dev")
    sample = domain.aliro_configs.create!(created_by: users(:alice), name: "s",
      reader_group_id: GID, reader_public_key: PUB, is_sample: true)
    domain.aliro_configs.create!(created_by: users(:alice), name: "p",
      reader_group_id: GID, reader_public_key: PUB, is_sample: false)
    assert_equal [ sample ], domain.sample_configs.to_a
  end
end
