require 'rails/railtie'
require 'intermodal/api/railties'
require 'intermodal/rack/rescue'

require 'active_support/core_ext/module/delegation'

# Modified from Rail 4.2 rails/engine.rb
module Intermodal
  class API < Rails::Railtie
    autoload :Configuration, "intermodal/api/configuration"

    include Intermodal::Mapping::DSL
    include Intermodal::DeclareControllers
    class_attribute :max_per_page, :default_per_page

    class << self
      attr_accessor :called_from

      alias :api_name    :railtie_name
      alias :engine_name :railtie_name

      delegate :eager_load!, to: :instance

      def inherited(base)
        unless base.abstract_railtie?
          Rails::Railtie::Configuration.eager_load_namespaces << base

          base.called_from = begin
            call_stack = if Kernel.respond_to?(:caller_locations)
              caller_locations.map { |l| l.absolute_path || l.path }
            else
              # Remove the line number from backtraces making sure we don't leave anything behind
              caller.map { |p| p.sub(/:\d+.*/, '') }
            end

            File.dirname(call_stack.detect { |p| p !~ %r[railties[\w.-]*/lib/rails|rack[\w.-]*/lib/rack] })
          end

          # Add another initializer each time this has been inherited
          # This covers a bug here, where the initializers declared in the API itself doesn't
          # seem to run for whatever reason.
          initializer "intermodal.load_#{base.name}", before: 'build_middleware_stack' do |app|
            base.generate_api!
          end
        end

        super
      end

      def endpoint(endpoint = nil)
        @endpoint ||= nil
        @endpoint = endpoint if endpoint
        @endpoint
      end

      def routes(&blk)
        if block_given?
          instance.routes(&blk)
        else
          instance.routes
        end
      end

      # Setup presenters, acceptors, and controllers
      def generate_api!
        self.load_presentations!
        self.load_controllers!
      end

    end

    delegate :middleware,  to: :config
    delegate :engine_name, to: :class
    delegate :api_name,    to: :class

    def initialize
      @app                 = nil
      @config              = nil
      @env_config          = nil
      @helpers             = nil
      @routes              = nil
      super
    end

    # Load console and invoke the registered hooks.
    # Check <tt>Rails::Railtie.console</tt> for more info.
    def load_console(app=self)
      require "rails/console/app"
      require "rails/console/helpers"
      run_console_blocks(app)
      self
    end

    # Load Rails runner and invoke the registered hooks.
    # Check <tt>Rails::Railtie.runner</tt> for more info.
    def load_runner(app=self)
      run_runner_blocks(app)
      self
    end

    # Load Rake, railties tasks and invoke the registered hooks.
    # Check <tt>Rails::Railtie.rake_tasks</tt> for more info.
    def load_tasks(app=self)
      require "rake"
      run_tasks_blocks(app)
      self
    end

    # Load Rails generators and invoke the registered hooks.
    # Check <tt>Rails::Railtie.generators</tt> for more info.
    def load_generators(app=self)
      require "rails/generators"
      run_generators_blocks(app)
      Rails::Generators.configure!(app.config.generators)
      self
    end

    # Eager load the application by loading all ruby
    # files inside eager_load paths.
    def eager_load!
      self.load_presentations!
      self.class.load_controllers!
      return
    end

    def railties
      @railties ||= Railties.new
    end

    # Returns a module with all the helpers defined for the engine.
    def helpers
      # returns empty module (for now)
      @helpers ||= begin
        Module.new
      end
    end

    # Returns the underlying rack application for this engine.
    def app
      @app ||= begin
        config.middleware = config.middleware.merge_into(default_middleware_stack)
        config.middleware.build(endpoint)
      end
    end

    # Returns the endpoint for this engine. If none is registered,
    # defaults to an ActionDispatch::Routing::RouteSet.
    def endpoint
      self.class.endpoint || routes
    end

    # Define the Rack API for this engine.
    def call(env)
      env.merge!(env_config)
      if env['SCRIPT_NAME']
        env["ROUTES_#{routes.object_id}_SCRIPT_NAME"] = env['SCRIPT_NAME'].dup
      end
      app.call(env)
    end

    # Defines additional Rack env configuration that is added on each call.
    def env_config
      @env_config ||= {
        'action_dispatch.routes' => routes
      }
    end

    # Defines the routes for this engine. If a block is given to
    # routes, it is appended to the engine.
    def routes
      @routes ||= ActionDispatch::Routing::RouteSet.new
      @routes.append(&Proc.new) if block_given?
      @routes
    end

    # Define the configuration object for the engine.
    def config
      @config ||= API::Configuration.new
    end

    initializer :add_routing_paths do |app|
      app.routes_reloader.route_sets << routes if routes?
    end

    initializer 'intermodal.load_x_auth_token_warden', :before => 'build_middleware_stack' do |app|
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

    initializer :engines_blank_point do
      # We need this initializer so all extra initializers added in engines are
      # consistently executed after all the initializers above across all engines.
    end

    def routes? #:nodoc:
      @routes
    end

    protected

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
      end
    end


  end
end
