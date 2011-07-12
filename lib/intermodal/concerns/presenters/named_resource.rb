module Intermodal
  module Presenters
    module NamedResource
      extend ActiveSupport::Concern

      included do
        include Intermodal::Presenters::Resource
        presents :name
      end
    end
  end
end
