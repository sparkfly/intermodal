module Intermodal
  module Models
    module AccessCredential 
      extend ActiveSupport::Concern

      included do
        include Intermodal::Models::Accountability

        # Validations
        validates_uniqueness_of :identity

        # Associations
        belongs_to :account

        def self.authenticate!(identity, key)
          ## MDB -- Added check for active account (access_credentials)
          ::Account.joins(:access_credentials).where(:access_credentials => { :identity => identity, :key => key, :active => TRUE }).limit(1).first
        end
      end
    end
  end
end
