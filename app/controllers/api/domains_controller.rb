require "base64"

module Api
  # Public, read-only JSON registry for a domain's sample configs.
  # No creator/email information is ever exposed.
  class DomainsController < ApplicationController
    def show
      name    = (params[:name] || params[:domain_name]).to_s.strip.downcase
      domain  = Domain.find_by(name: name)
      configs = domain ? domain.sample_configs : []

      render json: {
        domain: name,
        configs: configs.map { |c| serialize(c) }
      }
    end

    private

    def serialize(config)
      {
        name: config.name,
        reader_group_id: config.reader_group_id,
        reader_group_id_base64: b64(config.reader_group_id),
        reader_public_key: config.reader_public_key,
        reader_public_key_base64: b64(config.reader_public_key),
        reader_certificate: config.reader_certificate,
        reader_certificate_base64: config.cert? ? b64(config.reader_certificate) : nil,
        created_at: config.created_at.iso8601
      }
    end

    def b64(hex)
      Base64.strict_encode64([ hex ].pack("H*"))
    end
  end
end
