module Intermodal
  module Acceptors
    module Resource
      extend ActiveSupport::Concern

      # Explicit blacklist
      included do
        exclude_from_acceptance :id, :created_at, :updated_at, :account_id
      end
    end
  end
end
