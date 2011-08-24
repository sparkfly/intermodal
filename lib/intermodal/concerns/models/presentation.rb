module Intermodal
  module Models
    module Presentation
      extend ActiveSupport::Concern

      def as_json(opts = {})
        return presenter(opts) if opts && (opts[:presenter] || opts[:api])
        super(opts)
      end

      def presenter(opts)
        raise "Must pass :presenter" unless opts[:presenter]
        presenter = opts[:presenter] || opts[:api].presenter_for(self.class)
        presenter.call(self, opts[:scope] || :default)
      end
    end
  end
end
