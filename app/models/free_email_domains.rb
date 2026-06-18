require "yaml"
require "set"

# Loads the free-mail blocklist (config/free_email_domains.yml) used to reject
# consumer email providers at login.
module FreeEmailDomains
  PATH = Rails.root.join("config", "free_email_domains.yml")

  def self.list
    @list ||= Set.new(Array(YAML.load_file(PATH)).map { |d| d.to_s.strip.downcase })
  end

  def self.include?(domain)
    return false if domain.blank?

    list.include?(domain.to_s.strip.downcase)
  end

  def self.reload!
    @list = nil
    list
  end
end
