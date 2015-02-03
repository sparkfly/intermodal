module Intermodal
  module Models
    module DbAccessToken
      extend ActiveSupport::Concern

      included do
        TOKEN_SIZE = 32

        # Validations
        validates_uniqueness_of :token

        # Associations
        belongs_to :account

        def self.authenticate!(token)
          ::Account.joins(:access_tokens).where(:access_tokens => { :token => token }).limit(1).first
        end

        def self.generate!(account)
          token = new(:account_id => account.id)
          begin
            token.token = SecureRandom.hex(TOKEN_SIZE)
          end until token.valid?
          return token.token if token.save
        end
      end
    end
  end
end
