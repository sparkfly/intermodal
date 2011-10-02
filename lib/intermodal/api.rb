module Intermodal
  module API
    extend ActiveSupport::Concern

    included do
      include Intermodal::Mapping::DSL
      extend Intermodal::DeclareControllers
      class_attribute :routes, :max_per_page, :default_per_page

      # Configure
      self.max_per_page = Intermodal.max_per_page
      self.default_per_page = Intermodal.default_per_page

      initializer 'intermodal.load_presentation', :after => 'load_config_initializer' do
        self.load_presentations!
      end

      initializer 'intermodal.load_controllers', :after => 'load_config_initializer' do
        self.class.load_controllers!
      end

      initializer 'intermodal.load_x_auth_token_warden', :before => 'load_config_initializer' do
        Warden::Strategies.add(:x_auth_token) do
          def valid?
            env['HTTP_X_AUTH_TOKEN']
          end

          def authenticate!
            a = AccessToken.authenticate!(env['HTTP_X_AUTH_TOKEN'])
            a.nil? ? fail!("Could not log in") : success!(a)
          end
        end
      end

      def default_middleware_stack
        ActionDispatch::MiddlewareStack.new.tap do |middleware|
          middleware.use ::Rack::Lock
          middleware.use ::Rack::Runtime
          middleware.use ::Rails::Rack::Logger
          #middleware.use ::ActionDispatch::RemoteIp, config.action_dispatch.ip_spoofing_check, config.action_dispatch.trusted_proxies
          #middleware.use ::Rack::Sendfile, config.action_dispatch.x_sendfile_header
          #middleware.use ::ActionDispatch::Callbacks, !config.cache_classes

          # TODO: Find a way to patch Warden so this is not necessary
          # middleware.use config.session_store, config.session_options
          # Use random secret for now until we can get rid of this.
          middleware.use ::ActionDispatch::Session::AbstractStore
          middleware.use ::ActionDispatch::Flash
          middleware.use Warden::Manager do |manager|
            manager.default_strategies :x_auth_token #, :basic
            manager.failure_app = proc do
              Intermodal::Rack::Auth::UNAUTHORIZED
            end
          end

          middleware.use ::ActionDispatch::ParamsParser
          middleware.use ::Rack::MethodOverride
          middleware.use ::ActionDispatch::Head
        end
      end
    end
  end
end
