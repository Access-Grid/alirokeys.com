class ConfigsController < ApplicationController
  # Public sample config page.
  def show
    @config = SampleData.find(params[:id])
    head :not_found unless @config && @config.domain == params[:domain_name] && @config.is_sample
  end

  # Per-language source export (download).
  def export
    config = SampleData.find(params[:id])
    return head :not_found unless config && config.domain == params[:domain_name]

    langdef = helpers.export_langs.find { |l| l[:ext] == params[:format] }
    code = helpers.code_export(config, langdef ? langdef[:key] : params[:format])
    send_data code,
              filename: "#{config.name.parameterize}.#{params[:format]}",
              type: "text/plain", disposition: "attachment"
  end
end
