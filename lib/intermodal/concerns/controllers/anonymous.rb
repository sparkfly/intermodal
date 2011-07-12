module Intermodal
  module Controllers
    module Anonymous
      extend ActiveSupport::Concern

      protected

      # Hacks to get anonymous controllers working
      def reloadable?(app)
        false
      end

      module ClassMethods
        def anonymous?
          true
        end

        def controller_path
          'anonymous_web_service'
        end
      end
    end
  end
end
