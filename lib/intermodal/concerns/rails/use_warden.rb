require 'intermodal/rack/auth'

# Use this to configure Warden to use X_AUTH_TOKEN strategy
module Intermodal
  module Rails
    module UseWarden
      extend ActiveSupport::Concern

      included do
        config.middleware.use Warden::Manager do |manager|
          manager.default_strategies :x_auth_token #, :basic
          manager.failure_app = proc do
            Intermodal::Rack::Auth::UNAUTHORIZED
          end
        end
      end
    end
  end
end
