require 'intermodal/rack/rescue'

module Intermodal
  module Concerns
    module Rails
      module Rails3Stack
        extend ActiveSupport::Concern
        # Override the middleware stack to something more streamlined

        included do
          def default_middleware_stack
            ActionDispatch::MiddlewareStack.new.tap do |middleware|
              #middleware.use ::Rack::Lock unless config.allow_concurrency
              middleware.use ::Rack::Runtime
              middleware.use ::Intermodal::Rack::Rescue
              middleware.use ::Rails::Rack::Logger
              middleware.use ::ActionDispatch::RemoteIp, config.action_dispatch.ip_spoofing_check, config.action_dispatch.trusted_proxies
              middleware.use ::Rack::Sendfile, config.action_dispatch.x_sendfile_header
              middleware.use ::ActionDispatch::Callbacks #, !config.cache_classes

              if config.session_store
                middleware.use config.session_store, config.session_options
                middleware.use ::ActionDispatch::Flash
              end

              middleware.use ::ActionDispatch::ParamsParser
              middleware.use ::Rack::MethodOverride
              middleware.use ::ActionDispatch::Head
            end
          end

          # Query caching doesn't work well with what we are doing
          # Maybe this has changed since Rails 4.
          initializer 'intermodal_example.hack_active_record', :after => 'eager_load!' do
            config.middleware.delete ActiveRecord::QueryCache
          end
        end

      end
    end
  end
end
