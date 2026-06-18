require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "normalizes email to stripped lowercase" do
    user = User.create!(email: "  AB@Allegion.COM ")
    assert_equal "ab@allegion.com", user.email
  end

  test "requires a present, valid email" do
    assert_not User.new(email: "").valid?
    assert_not User.new(email: "not-an-email").valid?
  end

  test "rejects free-mail providers" do
    %w[bob@gmail.com x@outlook.com y@proton.me z@icloud.com].each do |email|
      user = User.new(email: email)
      assert_not user.valid?, "#{email} should be invalid"
      assert(user.errors[:email].any? { |m| m.include?("organization") })
    end
  end

  test "accepts organization emails" do
    assert User.new(email: "ab@allegion.com").valid?
    assert User.new(email: "dev@kastle.io").valid?
  end

  test "email is unique case-insensitively" do
    User.create!(email: "ab@allegion.com")
    assert_not User.new(email: "AB@allegion.com").valid?
  end
end
