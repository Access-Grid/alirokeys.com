require "test_helper"

class OneTimeShareTest < ActiveSupport::TestCase
  GID = "17cb8ab0dcd640f3a03cfa2aae7a5775".freeze
  PUB = "0418e0ba2eef5406549f7ece418ab14af261585de89c141bed7411a9a0f4be1e4cdd6718002dd6163b75e959cb89548a959380d341040e0adf3f557384337b6e89".freeze

  setup do
    @config = users(:alice).aliro_configs.create!(name: "C", domain_name: "acme.dev",
      reader_group_id: GID, reader_public_key: PUB)
  end

  test "mint! returns a plaintext secret but stores only a digest" do
    share, secret = OneTimeShare.mint!(config: @config)
    assert secret.present?
    assert share.token.present?
    assert share.authenticate_secret(secret)
    refute share.authenticate_secret("wrong-secret")
    assert share.secret_digest.present?
  end

  test "retrievable? reflects fresh / expired / consumed state" do
    share, = OneTimeShare.mint!(config: @config)
    assert share.retrievable?

    share.update!(expires_at: 1.minute.ago)
    refute share.retrievable?

    share.update!(expires_at: 1.hour.from_now, retrieved_at: Time.current)
    refute share.retrievable?
  end

  test "claim! succeeds only once" do
    share, = OneTimeShare.mint!(config: @config)
    assert share.claim!
    refute share.claim!
  end
end
