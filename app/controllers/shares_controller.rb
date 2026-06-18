class SharesController < ApplicationController
  before_action :authenticate_user!, only: :create
  rate_limit to: 10, within: 1.minute, only: :reveal

  # Mint a one-time share for one of the current user's configs.
  def create
    @config = current_user.aliro_configs.find(params[:aliro_config_id])
    @share, @secret = OneTimeShare.mint!(config: @config)
    @token = @share.token
    render :created
  end

  # Enter-secret screen (or "unavailable" if already consumed/expired).
  def show
    @token = params[:token]
    share = OneTimeShare.find_by(token: @token)
    render_unavailable unless share&.retrievable?
  end

  # Verify the secret, then burn: reveal the config once and destroy it.
  def reveal
    @token = params[:token]
    share = OneTimeShare.find_by(token: @token)
    return render_unavailable unless share&.retrievable?

    unless share.authenticate_secret(params[:secret].to_s)
      flash.now[:alert] = "Incorrect secret."
      return render :show, status: :unprocessable_entity
    end

    return render_unavailable unless share.claim! # atomic single-use guard

    @config = share.aliro_config
    @config&.destroy!
    share.update_columns(aliro_config_id: nil)
    render :revealed
  end

  private

  def render_unavailable
    render :used, status: :gone
  end
end
