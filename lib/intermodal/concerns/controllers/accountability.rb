module Intermodal
  module Controllers
    module Accountability
      extend ActiveSupport::Concern

      included do
        include Intermodal::Let

        before_filter :authentication

        let(:account) { env['warden'].user }
      end

      protected

      def authentication
        throw(:warden) unless env['warden'].authenticate?
      end
    end
  end
end
