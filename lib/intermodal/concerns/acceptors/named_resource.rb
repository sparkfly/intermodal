module Intermodal
  module Acceptors
    module NamedResource
      extend ActiveSupport::Concern

      included do
        include Intermodal::Acceptors::Resource
        accepts :name
      end
    end
  end
end
