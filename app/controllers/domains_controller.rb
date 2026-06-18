class DomainsController < ApplicationController
  def show
    @domain  = params[:domain_name]
    domain   = Domain.find_by(name: @domain.to_s.downcase)
    @configs = domain ? domain.sample_configs : AliroConfig.none
  end
end
