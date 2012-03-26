require 'machinist/active_record'
require 'forgery'
require 'faker'
require 'spec/support/app/schema'

SHAM = {
  :email => lambda { Forgery::Internet.email_address },
  :key   => lambda { SecureRandom.hex(32) },
  :company_name => lambda { [ ( rand(3) > 1 ? Faker::Company.name : Forgery::Name.company_name ),
    Forgery::Address.country ].join(' ') } }

# Load the schema before setting up the blueprints
# Supported adapters: sqlite3 and postgresql
SpecHelpers::Schema.new(:sqlite3).up!

# Blueprints
Account.blueprint do
  name { SHAM[:company_name].call() }
end

AccessCredential.blueprint do
  account  { Account.make! }
  identity { SHAM[:email].call() }
  key      { SHAM[:key].call() }
end

Item.blueprint do
  account  { Account.make! }
  name     { "Item ##{sn}" }
end

Part.blueprint do
  item     { Item.make! }
  name     { "Part ##{sn}" }
end

Vendor.blueprint do
  account  { Account.make! }
  name     { SHAM[:company_name].call() }
end

