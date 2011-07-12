module Intermodal
  module Presenters
    module Resource
      extend ActiveSupport::Concern

      included do
        presents :id

        presents :created_at
        presents :updated_at
      end
    end
  end
end
