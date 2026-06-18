class DomainsController < ApplicationController
  def show
    @domain  = params[:domain_name]
    @configs = SampleData.sample_configs_for(@domain)
  end
end
