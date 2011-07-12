module Intermodal
  module Models
    module Presentation
      extend ActiveSupport::Concern

      attr_accessor :api

      def as_json(opt={})
        presenter
      end

      def presenter
        api.presents_resource(self)
      end

      def api
        @api || raise "Unimplemented"
      end
    end
  end
end
