module SpecHelpers
  module Epiphyte
    extend ActiveSupport::Concern

    # TODO:
    # For some reason, Rails::Railstie::Configurable does not
    # pick up routes within the engine. I don't know if this
    # has to do with the way I loaded the API in specs, or
    # if there is a bug in Rails. I'm leaving this here for
    # now.

    included do
      def initializers
        @initializers ||= self.class.initializers_for(self)
      end

      def initialize!
        raise "Application has been already initialized." if @initialized
        run_initializers(self)
        @initialized = true
        self
      end

      def config
        @config ||= Rails::Engine::Configuration.new(File.dirname(__FILE__))
      end

      def self.routes
        instance.routes
      end

      def routes
        @routes ||= ActionDispatch::Routing::RouteSet.new
        @routes.append(&Proc.new) if block_given?
        @routes
      end
    end
  end
end
