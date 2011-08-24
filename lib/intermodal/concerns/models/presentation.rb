module Intermodal
  module Models
    module Presentation
      extend ActiveSupport::Concern

      def as_json(opts = {})
        return presentation(opts) if opts && (opts[:presenter] || opts[:api])
        super(opts)
      end

      def presenter(opts)
        opts[:presenter] || opts[:api].presenter_for(self.class)
      end

      def presentation(opts)
        presenter(opts).call(self, opts[:scope] || :default)
      end
    end
  end
end
