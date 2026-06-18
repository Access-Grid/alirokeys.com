class DashboardController < ApplicationController
  before_action :mock_sign_in

  def show
    @configs = SampleData.for_user
  end
end
