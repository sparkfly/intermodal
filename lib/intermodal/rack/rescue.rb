#require 'action_dispatch/http/mime_type'

module Intermodal
  module Rack
    class Rescue
      include ActionController::Rescue

      def self.watch(x)
        ap x if defined? ap
      end

      def watch(x)
        self.class.watch(x)
      end

      rescue_from Exception do |exception|
        if defined? Rails and Rails.env == 'production'
          [500, {}, [ "Unexpected error. Please contact support." ] ]
        else
          [500, {}, [ "Exception: #{exception.message}", "\n\n", exception.backtrace ].tap(&method(:watch)) ]
        end
      end

      rescue_from ActiveRecord::RecordNotFound do |exception|
        [404, {}, [ 'Not Found' ] ]
      end

      rescue_from ActionController::RoutingError do |exception|
        if defined? Rails and Rails.env == 'production'
          [404, {}, ['Not Found'] ]
        else
          [500, {}, [ "Exception: #{exception.message}", "\n", caller.join("\n"), "\n", exception.backtrace ].tap(&method(:watch)) ]
        end
      end

      # TODO: Hack. Untested.
      if defined? ActiveResource::ResourceNotFound
        rescue_from ActiveResource::ResourceNotFound do |exception|
          [404, {}, [ 'Not Found' ] ]
        end
      end

      rescue_from MultiJson::DecodeError do |exception|
        [400, { 'Content-Type' => content_type(:json) }, { :parse_error => exception.message }.to_json]
      end

      rescue_from 'REXML::ParseException' do |exception|
        [400, { 'Content-Type' => content_type(:xml) }, { :parse_error => exception.message }.to_xml]
      end

      def content_type(format)
        "#{Mime::Type.lookup_by_extension(format)}; charset=utf-8"
      end

      def initialize(app, &block)
        @app = app
        self.class.instance_eval(&block) if block_given?
      end

      def call(env)
        @app.call(env)
      rescue Exception => exception
        rescue_with_handler(exception) || raise(exception)
      end

      # Overrides ActiveSuppor::Rescuable#rescue_with_handler
      # All handlers *MUST* respond with a valid Rack response
      def rescue_with_handler(exception)
        return unless handler = handler_for_rescue(exception)
        handler.arity != 0 ? handler.call(exception) : handler.call
      end
    end
  end
end
