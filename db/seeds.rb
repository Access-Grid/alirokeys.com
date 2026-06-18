# Sample Aliro configs for local/demo use. Idempotent.
KASTLE_CERT = "3081b2040200003081ab820d3235313230313030303030305a830d3236303630313030303030305a8542000477f673d22eb6fa831d8c47e82004a2a85202276df1f12ee4fbe42f9e136265c65fa430afcd377ac3e3688c59d8696f783affb6df337de9fb25a0ece77123c017864700304402200359ac1c198d818b4cee4e1313711abf4e246339666f8897ea642c42f869153b022023e7d8d583f7f6564aa1393a15742d318e7fe8ff310160acea75c7dbf0e86542".freeze

seeds = [
  { name: "Front Door Reader",   domain: "allegion.com", by: "ab@allegion.com",
    gid: "17cb8ab0dcd640f3a03cfa2aae7a5775",
    pub: "0418e0ba2eef5406549f7ece418ab14af261585de89c141bed7411a9a0f4be1e4cdd6718002dd6163b75e959cb89548a959380d341040e0adf3f557384337b6e89",
    cert: nil, sample: true },
  { name: "Parking Garage Reader", domain: "allegion.com", by: "security@allegion.com",
    gid: "bcbc8068c73b4a22b52403e5070de64e",
    pub: "0477f673d22eb6fa831d8c47e82004a2a85202276df1f12ee4fbe42f9e136265c65fa430afcd377ac3e3688c59d8696f783affb6df337de9fb25a0ece77123c017",
    cert: KASTLE_CERT, sample: true },
  { name: "Staging Door (unlisted)", domain: "allegion.com", by: "ab@allegion.com",
    gid: "a1b2c3d4e5f60718293a4b5c6d7e8f90",
    pub: "0418e0ba2eef5406549f7ece418ab14af261585de89c141bed7411a9a0f4be1e4cdd6718002dd6163b75e959cb89548a959380d341040e0adf3f557384337b6e89",
    cert: nil, sample: false },
  { name: "Pixel Reader Profile", domain: "google.com", by: "keys@google.com",
    gid: "7fbcae4a67604cf4b60fd10c445d1f0d",
    pub: "040726e1af2cebabf54799d452d830b6e2ace9e2186c1228d51a57366356b4adcd513fc62b8c9075e278289af7ff7c0aee88b1bd44e2f8e510f22e6632d3f2a64d",
    cert: nil, sample: true },
  { name: "Elatec Reader (Kastle)", domain: "kastle.com", by: "dev@kastle.com",
    gid: "bcbc8068c73b4a22b52403e5070de64e",
    pub: "0477f673d22eb6fa831d8c47e82004a2a85202276df1f12ee4fbe42f9e136265c65fa430afcd377ac3e3688c59d8696f783affb6df337de9fb25a0ece77123c017",
    cert: KASTLE_CERT, sample: true }
]

seeds.each do |s|
  user   = User.find_or_create_by!(email: s[:by])
  domain = Domain.find_or_create_by!(name: s[:domain])
  AliroConfig.find_or_create_by!(name: s[:name], domain: domain) do |c|
    c.created_by         = user
    c.reader_group_id    = s[:gid]
    c.reader_public_key  = s[:pub]
    c.reader_certificate = s[:cert]
    c.is_sample          = s[:sample]
  end
end

puts "Seeded: #{User.count} users, #{Domain.count} domains, #{AliroConfig.count} configs"
