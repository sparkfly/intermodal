module Intermodal
  module Models
    module Presentation
      extend ActiveSupport::Concern

      def as_json(opts = {})
        return presentation(opts) if opts && (opts[:presenter] || opts[:api])
        super(opts)
      end

      def to_xml(opts = {})
        return presentation(opts.except(:root)).to_xml(opts) if opts && (opts[:presenter] || opts[:api])
        super(opts)
      end

      def presenter(opts)
        opts[:presenter] || opts[:api].presenter_for(self.class)
      end

      def presentation(opts)
        presenter(opts).call(self, opts)
      end
    end
  end
end
