require "test_helper"

class FreeEmailDomainsTest < ActiveSupport::TestCase
  test "flags free-mail domains (case/whitespace-insensitive)" do
    assert FreeEmailDomains.include?("gmail.com")
    assert FreeEmailDomains.include?("GMAIL.COM")
    assert FreeEmailDomains.include?(" outlook.com ")
  end

  test "allows organization domains and blanks" do
    assert_not FreeEmailDomains.include?("allegion.com")
    assert_not FreeEmailDomains.include?(nil)
    assert_not FreeEmailDomains.include?("")
  end
end
