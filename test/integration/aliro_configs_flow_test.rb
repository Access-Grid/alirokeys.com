require "test_helper"

class AliroConfigsFlowTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  GID = "17cb8ab0dcd640f3a03cfa2aae7a5775".freeze
  PUB = "0418e0ba2eef5406549f7ece418ab14af261585de89c141bed7411a9a0f4be1e4cdd6718002dd6163b75e959cb89548a959380d341040e0adf3f557384337b6e89".freeze

  setup { @user = users(:alice); sign_in @user }

  test "signed-in user creates a config attributed to them" do
    assert_difference "AliroConfig.count", 1 do
      post aliro_configs_path, params: { aliro_config: {
        name: "Door", domain_name: "acme.dev", reader_group_id: GID,
        reader_public_key: PUB, is_sample: "1" } }
    end
    assert_redirected_to dashboard_path
    assert_equal @user, AliroConfig.last.created_by
    assert_equal "acme.dev", AliroConfig.last.domain.name
  end

  test "domain is derived from the creator's email and a submitted domain is ignored" do
    # alice is alice@acme.dev — the submitted domain_name must not be honored
    post aliro_configs_path, params: { aliro_config: {
      name: "Door", domain_name: "evil.example.com", reader_group_id: GID, reader_public_key: PUB } }
    assert_redirected_to dashboard_path
    assert_equal "acme.dev", AliroConfig.last.domain.name
  end

  test "invalid key material re-renders the form with errors" do
    assert_no_difference "AliroConfig.count" do
      post aliro_configs_path, params: { aliro_config: {
        name: "Door", domain_name: "acme.dev", reader_group_id: "abcd", reader_public_key: PUB } }
    end
    assert_response :unprocessable_entity
    assert_match "16 bytes", response.body
  end

  test "a non-creator cannot edit another user's config" do
    config = others_config
    get edit_aliro_config_path(config)
    assert_response :not_found
  end

  test "a non-creator cannot delete another user's config" do
    config = others_config
    assert_no_difference "AliroConfig.count" do
      delete aliro_config_path(config)
    end
    assert_response :not_found
    assert AliroConfig.exists?(config.id)
  end

  def others_config
    users(:bob).aliro_configs.create!(name: "Theirs", domain_name: "acme.dev",
      reader_group_id: GID, reader_public_key: PUB)
  end

  test "creating requires authentication" do
    sign_out @user
    get new_aliro_config_path
    assert_redirected_to new_user_session_path
  end
end
