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
          ::Account.joins(:access_credentials).where(:access_credentials => { :identity => identity, :key => key }).limit(1).first
        end
      end
    end
  end
end
