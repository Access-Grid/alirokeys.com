class AliroConfigsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_config, only: %i[edit update destroy]

  def new
    @config = current_user.aliro_configs.new(is_sample: true)
  end

  def create
    @config = current_user.aliro_configs.new(config_params)
    if @config.save
      redirect_to dashboard_path, notice: "Config “#{@config.name}” created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @config.update(config_params)
      redirect_to dashboard_path, notice: "Config “#{@config.name}” updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @config.destroy
    redirect_to dashboard_path, notice: "Config deleted."
  end

  private

  # Creator-scoped: other users' configs are simply not found (404).
  def set_config
    @config = current_user.aliro_configs.find(params[:id])
  end

  def config_params
    # domain is derived from the creator's email domain, never user-supplied.
    params.require(:aliro_config).permit(
      :name, :reader_group_id, :reader_public_key, :reader_certificate, :is_sample
    )
  end
end
