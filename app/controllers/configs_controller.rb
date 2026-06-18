class ConfigsController < ApplicationController
  before_action :set_config

  # Public sample config page.
  def show
    head :not_found unless @config&.is_sample?
  end

  # Per-language source export (download). Public for sample configs.
  def export
    return head :not_found unless @config&.is_sample?

    langdef = helpers.export_langs.find { |l| l[:ext] == params[:format] }
    code = helpers.code_export(@config, langdef ? langdef[:key] : params[:format])
    send_data code,
              filename: "#{@config.name.parameterize}.#{params[:format]}",
              type: "text/plain", disposition: "attachment"
  end

  private

  def set_config
    domain = Domain.find_by(name: params[:domain_name].to_s.downcase)
    @config = domain&.aliro_configs&.find_by(id: params[:id])
  end
end
