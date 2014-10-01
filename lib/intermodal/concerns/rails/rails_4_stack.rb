module Intermodal
  module Concerns
    module Rails
      module Rails4Stack
        extend ActiveSupport::Concern

        # Delete extraneous middleware

        included do
          config.middleware.delete 'ActiveRecord::QueryCache'
          config.middleware.delete 'ActionDispatch::Cookies'
          config.middleware.delete 'ActionDispatch::Session::CookieStore'
        end
      end
    end
  end
end
