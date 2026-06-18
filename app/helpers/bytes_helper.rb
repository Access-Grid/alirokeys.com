require "base64"

# Renders raw byte material (stored as hex strings in the prototype) into the
# various copyable encodings and per-language source exports. This is real
# presentation logic, reused once live models land (Phase 4).
module BytesHelper
  # Per-field encodings, in display order. Returns { "Label" => "value" }.
  def field_encodings(hex)
    bytes = hex_to_bytes(hex)
    {
      "Hex"      => hex,
      "0x Hex"   => "0x#{hex}",
      "Base64"   => Base64.strict_encode64(bytes),
      "C array"  => c_array(bytes),
      "Swift"    => swift_array(bytes),
      "Java"     => java_array(bytes)
    }
  end

  # Languages offered for full-config export (label + file extension).
  EXPORT_LANGS = [
    { key: "json",   label: "JSON",   ext: "json" },
    { key: "c",      label: "C",      ext: "c" },
    { key: "swift",  label: "Swift",  ext: "swift" },
    { key: "python", label: "Python", ext: "py" },
    { key: "ruby",   label: "Ruby",   ext: "rb" },
    { key: "php",    label: "PHP",    ext: "php" },
    { key: "js",     label: "JS",     ext: "js" },
    { key: "java",   label: "Java",   ext: "java" }
  ].freeze

  def export_langs = EXPORT_LANGS

  # Full-config source export for a given language key.
  def code_export(config, lang)
    case lang.to_s
    when "json"   then export_json(config)
    when "c"      then export_c(config)
    when "swift"  then export_swift(config)
    when "python" then export_python(config)
    when "ruby"   then export_ruby(config)
    when "php"    then export_php(config)
    when "js"     then export_js(config)
    when "java"   then export_java(config)
    else "// unsupported language: #{lang}"
    end
  end

  private

  def hex_to_bytes(hex) = [hex].pack("H*")

  def byte_list(bytes, prefix: "0x", sep: ", ")
    bytes.bytes.map { |b| format("#{prefix}%02x", b) }.join(sep)
  end

  def c_array(bytes)    = "{ #{byte_list(bytes)} }"
  def swift_array(bytes) = "[#{byte_list(bytes)}]"
  def java_array(bytes) = "{ #{byte_list(bytes, prefix: "(byte)0x")} }"

  def header_lines(config)
    ["alirokeys — #{config.name} (#{config.domain})",
     "https://alirokeys.com/#{config.domain}/configs/samples/#{config.id}",
     "Generated sample — do not use in production."]
  end

  def comment(config, marker = "//")
    header_lines(config).map { |l| "#{marker} #{l}" }.join("\n")
  end

  def export_json(config)
    require "json"
    data = {
      name: config.name, domain: config.domain,
      reader_group_id: config.reader_group_id,
      reader_group_id_base64: Base64.strict_encode64(hex_to_bytes(config.reader_group_id)),
      reader_public_key: config.reader_public_key,
      reader_public_key_base64: Base64.strict_encode64(hex_to_bytes(config.reader_public_key)),
      reader_certificate: config.cert? ? config.reader_certificate : nil,
      reader_certificate_base64: config.cert? ? Base64.strict_encode64(hex_to_bytes(config.reader_certificate)) : nil
    }
    JSON.pretty_generate(data)
  end

  def export_c(config)
    lines = [comment(config), ""]
    lines << "static const uint8_t reader_group_id[] = #{c_array(hex_to_bytes(config.reader_group_id))};"
    lines << "static const uint8_t reader_public_key[] = #{c_array(hex_to_bytes(config.reader_public_key))};"
    lines << "static const uint8_t reader_certificate[] = #{c_array(hex_to_bytes(config.reader_certificate))};" if config.cert?
    lines.join("\n")
  end

  def export_swift(config)
    lines = [comment(config), ""]
    lines << "let readerGroupId: [UInt8] = #{swift_array(hex_to_bytes(config.reader_group_id))}"
    lines << "let readerPublicKey: [UInt8] = #{swift_array(hex_to_bytes(config.reader_public_key))}"
    lines << "let readerCertificate: [UInt8] = #{swift_array(hex_to_bytes(config.reader_certificate))}" if config.cert?
    lines.join("\n")
  end

  def export_python(config)
    lines = [comment(config, "#"), ""]
    lines << %(READER_GROUP_ID = bytes.fromhex("#{config.reader_group_id}"))
    lines << %(READER_PUBLIC_KEY = bytes.fromhex("#{config.reader_public_key}"))
    lines << %(READER_CERTIFICATE = bytes.fromhex("#{config.reader_certificate}")) if config.cert?
    lines.join("\n")
  end

  def export_ruby(config)
    lines = [comment(config, "#"), ""]
    lines << %(READER_GROUP_ID = ["#{config.reader_group_id}"].pack("H*"))
    lines << %(READER_PUBLIC_KEY = ["#{config.reader_public_key}"].pack("H*"))
    lines << %(READER_CERTIFICATE = ["#{config.reader_certificate}"].pack("H*")) if config.cert?
    lines.join("\n")
  end

  def export_php(config)
    lines = ["<?php", comment(config), ""]
    lines << %($reader_group_id = hex2bin("#{config.reader_group_id}");)
    lines << %($reader_public_key = hex2bin("#{config.reader_public_key}");)
    lines << %($reader_certificate = hex2bin("#{config.reader_certificate}");) if config.cert?
    lines.join("\n")
  end

  def export_js(config)
    lines = [comment(config), ""]
    lines << "export const readerGroupId = Uint8Array.from(#{swift_array(hex_to_bytes(config.reader_group_id))});"
    lines << "export const readerPublicKey = Uint8Array.from(#{swift_array(hex_to_bytes(config.reader_public_key))});"
    lines << "export const readerCertificate = Uint8Array.from(#{swift_array(hex_to_bytes(config.reader_certificate))});" if config.cert?
    lines.join("\n")
  end

  def export_java(config)
    lines = [comment(config), ""]
    lines << "static final byte[] READER_GROUP_ID = #{java_array(hex_to_bytes(config.reader_group_id))};"
    lines << "static final byte[] READER_PUBLIC_KEY = #{java_array(hex_to_bytes(config.reader_public_key))};"
    lines << "static final byte[] READER_CERTIFICATE = #{java_array(hex_to_bytes(config.reader_certificate))};" if config.cert?
    lines.join("\n")
  end
end
