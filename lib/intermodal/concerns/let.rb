# Ripped from Rspec 2.0 beta.12
module Intermodal
  module Let
    extend ActiveSupport::Concern

    private

    def __memoized # :nodoc:
      @__memoized ||= {}
    end

    module ClassMethods
      def let(name, &block)
        define_method(name) do
          __memoized[name] ||= instance_eval(&block)
        end
        protected(name)
      end
    end
  end
end
