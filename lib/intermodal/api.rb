module Intermodal
  class API < Rails::Railtie
    include Intermodal::Mapping::DSL
    extend Intermodal::DeclareControllers
    class_attribute :routes, :max_per_page, :default_per_page

    # Configure
    self.max_per_page = Intermodal.max_per_page
    self.default_per_page = Intermodal.default_per_page

    initializer 'intermodal.load_x_auth_token_warden', :before => 'build_middleware_stack' do
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

    def inherited(base)
      unless base.abstract_railtie?
        Rails::Railtie::Configuration.eager_load_namespaces << base

        base.called_from = begin
                             call_stack = if Kernel.respond_to?(:caller_locations)
                                            caller_locations.map(&:path)
                                          else
                                            # Remove the line number from backtraces making sure we don't leave anything behind
                                            caller.map { |p| p.sub(/:\d+.*/, '') }
                                          end

                             File.dirname(call_stack.detect { |p| p !~ %r[railties[\w.-]*/lib/rails|rack[\w.-]*/lib/rack] })
                           end
      end

      base.instance_eval do
        initializer "#{self.name}.load_presentation", :after => 'eager_load!' do
          self.load_presentations!
        end

        initializer "#{self.name}.load_controllers", :after => 'eager_load!' do
          self.class.load_controllers!
        end
      end

      super
    end

    def initialize
      @app                 = nil
      @config              = nil
      @env_config          = nil
      @routes              = nil
      super
    end

    # Returns the underlying rack application for this engine.
    def app
      @app ||= begin
        config.middleware = config.middleware.merge_into(default_middleware_stack)
        config.middleware.build(endpoint)
      end
    end

    def default_middleware_stack
      ActionDispatch::MiddlewareStack.new.tap do |middleware|
        middleware.use ::Intermodal::Rack::Rescue

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

   # Define the Rack API for this engine.
    def call(env)
      env.merge!(env_config)
      if env['SCRIPT_NAME']
        env.merge! "ROUTES_#{routes.object_id}_SCRIPT_NAME" => env['SCRIPT_NAME'].dup
      end
      app.call(env)
    end

    # Defines additional Rack env configuration that is added on each call.
    def env_config
      @env_config ||= {
        'action_dispatch.routes' => routes
      }
    end

    # Epiphyte (hack)
    # Apparently, Rails does not want you to define routes within the engine itself
    def self.routes(&blk)
      if block_given?
        instance.routes(&blk)
      else
        instance.routes
      end
    end

    def routes
      @routes ||= ActionDispatch::Routing::RouteSet.new
      @routes.append(&Proc.new) if block_given?
      @routes
    end
  end
end
