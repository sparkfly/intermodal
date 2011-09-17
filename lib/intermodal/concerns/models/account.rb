module Intermodal
  module Models
    module Account 
      extend ActiveSupport::Concern

      included do
        # Validations
        validates_presence_of :name

        # Associations
        has_many :access_tokens
        has_many :access_credentials
      end
    end
  end
end
