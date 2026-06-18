# Custom MIME types for per-language AliroConfig source exports.
# (json is registered by Rails already.)
{
  c:     "text/x-c",
  h:     "text/x-c",
  swift: "text/x-swift",
  py:    "text/x-python",
  rb:    "text/x-ruby",
  php:   "application/x-php",
  js:    "text/javascript",
  java:  "text/x-java-source"
}.each do |symbol, string|
  Mime::Type.register(string, symbol) unless Mime::Type.lookup_by_extension(symbol)
end
