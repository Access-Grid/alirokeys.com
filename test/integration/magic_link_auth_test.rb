require "test_helper"
require "cgi"

class MagicLinkAuthTest < ActionDispatch::IntegrationTest
  setup { ActionMailer::Base.deliveries.clear }

  test "free-mail sign-in is rejected and creates no user or email" do
    assert_no_difference "User.count" do
      post user_session_path, params: { user: { email: "bob@gmail.com" } }
    end
    assert_response :unprocessable_entity
    assert_match "organization email", response.body
    assert_empty ActionMailer::Base.deliveries
  end

  test "org email auto-provisions a user and emails a magic link" do
    assert_difference "User.count", 1 do
      post user_session_path, params: { user: { email: "New@Acme.dev" } }
    end
    assert_response :success
    assert_match(/check your email/i, response.body)
    assert_equal "new@acme.dev", User.last.email
    assert_equal 1, ActionMailer::Base.deliveries.size
  end

  test "following the magic link signs the user in" do
    post user_session_path, params: { user: { email: "ab@allegion.com" } }
    mail = ActionMailer::Base.deliveries.last
    link = mail.body.to_s[%r{https?://[^\s"'<>]*magic_link[^\s"'<>]*}]
    path = CGI.unescapeHTML(link.sub(%r{^https?://[^/]+}, ""))

    get path
    follow_redirect!
    get dashboard_path
    assert_response :success, "dashboard should be reachable once signed in"
  end

  test "protected pages redirect to sign-in when logged out" do
    get dashboard_path
    assert_redirected_to new_user_session_path
  end
end
