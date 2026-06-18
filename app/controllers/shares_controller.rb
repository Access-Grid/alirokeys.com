class SharesController < ApplicationController
  before_action :authenticate_user!, only: :create

  # Mint a one-time share (authed). Shows the link + one-time secret.
  def create
    @config = SampleData.find(params[:aliro_config_id])
    @token  = "k7Qm2xR9vL4pZ"
    @secret = "speckle-otter-marigold-49"
    render :created
  end

  # One-time retrieval UI. /s/used previews the already-consumed state.
  def show
    @token = params[:token]
    render :used if @token == "used"
  end

  # Submit the secret -> reveal the config (mock).
  def reveal
    @token  = params[:token]
    @config = SampleData.share_example
    render :revealed
  end
end
