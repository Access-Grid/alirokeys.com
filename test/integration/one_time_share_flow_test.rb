require "test_helper"

class OneTimeShareFlowTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  GID = "17cb8ab0dcd640f3a03cfa2aae7a5775".freeze
  PUB = "0418e0ba2eef5406549f7ece418ab14af261585de89c141bed7411a9a0f4be1e4cdd6718002dd6163b75e959cb89548a959380d341040e0adf3f557384337b6e89".freeze

  setup do
    @user = users(:alice)
    @config = @user.aliro_configs.create!(name: "Door", domain_name: "acme.dev",
      reader_group_id: GID, reader_public_key: PUB)
  end

  test "minting a share requires authentication" do
    post aliro_config_share_path(@config)
    assert_redirected_to new_user_session_path
  end

  test "only the creator can mint a share for a config" do
    sign_in users(:bob)
    post aliro_config_share_path(@config)
    assert_response :not_found
  end

  test "minting shows the retrieval link" do
    sign_in @user
    assert_difference "OneTimeShare.count", 1 do
      post aliro_config_share_path(@config)
    end
    assert_response :success
    assert_match %r{/s/}, response.body
  end

  test "wrong secret does not reveal or burn the config" do
    share, = OneTimeShare.mint!(config: @config)
    post reveal_share_path(share.token), params: { secret: "nope" }
    assert_response :unprocessable_entity
    assert AliroConfig.exists?(@config.id)
  end

  test "correct secret reveals the config once, then it is destroyed" do
    share, secret = OneTimeShare.mint!(config: @config)

    assert_difference "AliroConfig.count", -1 do
      post reveal_share_path(share.token), params: { secret: secret }
    end
    assert_response :success
    assert_match @config.reader_group_id, response.body

    # link is dead afterward
    get share_path(share.token)
    assert_response :gone
  end

  test "API native retrieval burns the config and returns language source" do
    share, secret = OneTimeShare.mint!(config: @config)

    assert_difference "AliroConfig.count", -1 do
      post api_share_path(share.token, format: :rb), params: { secret: secret }
    end
    assert_response :success
    assert_match "READER_GROUP_ID", response.body

    post api_share_path(share.token, format: :rb), params: { secret: secret }
    assert_response :gone
  end

  test "API native retrieval rejects a wrong secret" do
    share, = OneTimeShare.mint!(config: @config)
    post api_share_path(share.token, format: :rb), params: { secret: "wrong" }
    assert_response :unauthorized
    assert AliroConfig.exists?(@config.id)
  end
end
