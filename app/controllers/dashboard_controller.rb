class DashboardController < ApplicationController
  before_action :authenticate_user!

  def show
    @configs = current_user.aliro_configs.includes(:domain).order(:name)
  end
end
