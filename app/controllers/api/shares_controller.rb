module Api
  class SharesController < ApplicationController
    skip_forgery_protection

    # One-time retrieval API: render the config in the requested language, then
    # (in the real build) burn it. Mock returns the rendered source.
    def show
      config = SampleData.share_example
      langdef = helpers.export_langs.find { |l| l[:ext] == params[:format] }
      code = helpers.code_export(config, langdef ? langdef[:key] : "json")
      render plain: code, content_type: "text/plain"
    end
  end
end
