module Intermodal
  module Models
    module Presentation
      extend ActiveSupport::Concern

      attr_accessor :api

      def as_json(opt={})
        presenter((opt || {})[:scope])
      end

      def presenter(scope = :default)
        api.presents_resource(self, scope || :default)
      end

      def api
        raise "Unimplemented"
      end
    end
  end
end
