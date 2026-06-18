module Api
  # One-time retrieval API: verify the secret, render the config in the requested
  # language, then burn it (destroy the config). Single-use and rate-limited.
  class SharesController < ApplicationController
    skip_forgery_protection
    rate_limit to: 10, within: 1.minute

    def show
      share = OneTimeShare.find_by(token: params[:token])
      return head :gone unless share&.retrievable?
      return head :unauthorized unless share.authenticate_secret(params[:secret].to_s)
      return head :gone unless share.claim!

      config = share.aliro_config
      langdef = helpers.export_langs.find { |l| l[:ext] == params[:format] }
      code = helpers.code_export(config, langdef ? langdef[:key] : "json")

      config&.destroy!
      share.update_columns(aliro_config_id: nil)
      render plain: code, content_type: "text/plain"
    end
  end
end
