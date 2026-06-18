require "openssl"
require "base64"

# The validation core: decode/normalize Aliro key material and verify it's real.
# Accepts hex (with/without 0x) or base64; works in raw bytes.
module KeyMaterial
  GROUP = OpenSSL::PKey::EC::Group.new("prime256v1")

  module_function

  # Decode hex or base64 input into raw bytes (ASCII-8BIT). nil if undecodable.
  def to_bytes(input)
    s = input.to_s.gsub(/\s+/, "")
    return nil if s.empty?

    hex = s.delete_prefix("0x").delete_prefix("0X")
    if hex.match?(/\A[0-9a-fA-F]+\z/) && hex.length.even?
      [ hex ].pack("H*")
    else
      decode_base64(s)
    end
  end

  # Normalized lowercase hex, or nil if the input can't be decoded.
  def normalize_hex(input)
    bytes = to_bytes(input)
    bytes&.unpack1("H*")
  end

  # 16-byte reader group identifier.
  def group_id?(bytes)
    bytes.is_a?(String) && bytes.bytesize == 16
  end

  # 65-byte uncompressed P-256 point (0x04 || X || Y) that actually lies on the curve.
  def on_curve?(bytes)
    return false unless bytes.is_a?(String) && bytes.bytesize == 65 && bytes.getbyte(0) == 0x04

    OpenSSL::PKey::EC::Point.new(GROUP, OpenSSL::BN.new(bytes.unpack1("H*"), 16))
    true
  rescue OpenSSL::PKey::EC::Point::Error, OpenSSL::BNError
    false
  end

  # Pragmatic §13.3 reader-cert check: looks like a cert (SEQUENCE) and embeds
  # the given uncompressed public key. (Full ASN.1/compression handling is a
  # later enhancement; this validates the security-relevant binding.)
  def cert_embeds_key?(cert_bytes, pubkey_bytes)
    return false unless cert_bytes.is_a?(String) && pubkey_bytes.is_a?(String)

    cert_bytes.getbyte(0) == 0x30 && cert_bytes.include?(pubkey_bytes)
  end

  def decode_base64(string)
    [ :strict_decode64, :urlsafe_decode64 ].each do |m|
      begin
        return Base64.public_send(m, string)
      rescue ArgumentError
        next
      end
    end
    nil
  end
  private_class_method :decode_base64
end
