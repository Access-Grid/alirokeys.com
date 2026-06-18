class SessionsController < ApplicationController
  # Magic-link request form
  def new
    @email = params[:email]
  end

  # Mock: "send" the magic link, show the check-your-email screen.
  def create
    @email = params[:email].to_s.strip
    render :check_email
  end

  def destroy
    redirect_to root_path, notice: "Signed out."
  end
end
