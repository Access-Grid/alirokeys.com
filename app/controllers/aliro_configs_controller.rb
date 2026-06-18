class AliroConfigsController < ApplicationController
  before_action :mock_sign_in

  def new
    # Add ?errors=1 to preview the validation-error state of the form.
    @show_errors = params[:errors].present?
  end

  def create
    redirect_to dashboard_path, notice: "Config created (mock)."
  end

  def edit
    @config = SampleData.find(params[:id])
  end

  def update
    redirect_to dashboard_path, notice: "Config updated (mock)."
  end

  def destroy
    redirect_to dashboard_path, notice: "Config deleted (mock)."
  end
end
