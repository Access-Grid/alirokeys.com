class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  private

  # Phase 0 mock: pretend a user is signed in so the authed UI (nav, dashboard,
  # forms) renders realistically. Replaced by Devise current_user in Phase 2.
  def mock_sign_in
    @current_user_email = SampleData::MOCK_USER
  end
end
