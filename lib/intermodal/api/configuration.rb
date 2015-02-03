require 'rails/railtie/configuration'


# Modified from Rails 4.2 rails/engine/configuration.rg
module Intermodal
  class API
    class Configuration < ::Rails::Railtie::Configuration
      attr_writer :middleware

      def initialize
        super()
        @generators = app_generators.dup
      end

      # Returns the middleware stack for the engine.
      def middleware
        @middleware ||= Rails::Configuration::MiddlewareStackProxy.new
      end

      # Holds generators configuration:
      #
      #   config.generators do |g|
      #     g.orm             :data_mapper, migration: true
      #     g.template_engine :haml
      #     g.test_framework  :rspec
      #   end
      #
      # If you want to disable color in console, do:
      #
      #   config.generators.colorize_logging = false
      #
      def generators #:nodoc:
        @generators ||= Rails::Configuration::Generators.new
        yield(@generators) if block_given?
        @generators
      end

    end
  end
end
