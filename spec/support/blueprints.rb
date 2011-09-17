require 'machinist/active_record'
require 'forgery'
require 'faker'


# Blueprints 
module SpecHelpers
  module Blueprints
    extend ActiveSupport::Concern

    included do
      def blueprints
        sham = { 
          :email => lambda { Forgery::Internet.email_address },
          :key   => lambda { SecureRandom.hex(32) },
          :company_name => lambda { [ ( rand(3) > 1 ? Faker::Company.name : Forgery::Name.company_name ),
            Forgery::Address.country ].join(' ') } }

        Account.blueprint do
          name { sham[:company_name].call() }
        end

        AccessCredential.blueprint do
          account  { Account.make! }
          identity { sham[:email].call() }
          key      { sham[:key].call() }
        end
      end
    end
  end
end

