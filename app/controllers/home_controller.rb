class HomeController < ApplicationController
  def landing
    @q = params[:q].to_s.strip.downcase
    # A domain-looking query jumps straight to that domain's public profile.
    if @q.match?(/\A[a-z0-9][a-z0-9.\-]*\.[a-z]{2,}\z/)
      redirect_to domain_profile_path(@q)
    end
  end
end
