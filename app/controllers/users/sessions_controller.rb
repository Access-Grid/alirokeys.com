module Users
  # Passwordless magic-link sign-in. Auto-provisions a user for any valid
  # organization email, then emails a one-time login link.
  class SessionsController < Devise::Passwordless::SessionsController
    rate_limit to: 5, within: 1.minute, only: :create

    def new
      self.resource = User.new
      super
    end

    def create
      email = sign_in_params[:email].to_s.strip.downcase
      user = User.find_or_initialize_by(email: email)

      if user.persisted? || user.save
        user.send_magic_link
        @email = email
        render :check_email
      else
        self.resource = user
        flash.now[:alert] = user.errors.full_messages.first
        render :new, status: :unprocessable_entity
      end
    end

    private

    def sign_in_params
      params.fetch(resource_name, {}).permit(:email)
    end
  end
end
