#require 'action_dispatch/http/mime_type'

module Intermodal
  module Rack
    class Rescue
      include ActionController::Rescue

      rescue_from Exception do |exception|
        [500, {}, exception.message]
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
