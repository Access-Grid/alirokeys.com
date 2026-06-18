class DashboardController < ApplicationController
  before_action :authenticate_user!

  def show
    # TODO Phase 3: scope to current_user.aliro_configs
    @configs = SampleData.all
  end
end
