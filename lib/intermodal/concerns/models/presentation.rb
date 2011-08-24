module Intermodal
  module Models
    module Presentation
      extend ActiveSupport::Concern

      def as_json(opts = {})
        return presenter(opts) if opts && opts[:presenter]
        super(opts)
      end

      def presenter(opts)
        raise "Must pass :presenter" unless opts[:presenter]
        opts[:presenter].call(self, opts[:scope] || :default)
      end
    end
  end
end
