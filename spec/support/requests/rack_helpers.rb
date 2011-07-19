module SpecHelpers
  module Rack
    extend ActiveSupport::Concern

    class SimpleXMLParser
      def self.parse(*args)
        Hash.from_xml(*args)
      end
    end

    included do
      subject { response }

      let(:application) { Ignite::Application }
      let(:http_headers) { Hash.new }
      let(:request_headers) do
        http_headers.to_a.inject({}) do |m,kv|
           m.tap do |_m|
            _h, _v = kv
            _m["HTTP_#{_h}".underscore.upcase] = _v
          end
        end
      end
      let(:request_url_prefix) { '' }

      let(:response) { application.call(request) }
      let(:status) { response[0] }
      let(:response_headers) { response[1] }
      let(:content_type) { response_headers['Content-Type'] }
      let(:raw_body) do
        # http://rack.rubyforge.org/doc/files/SPEC.html
        # Rack Spec says response[2] should respond to #each and we
        # cannot gaurantee this is an ActionDispatch::Response

        # This calls each on all the chunks in-memory and gives it back as a whole string

        [].tap do |out|
          response[2].each do |chunk|
            out << chunk
          end
        end.join
      end
      let(:body) { parser.parse(raw_body) }

      let(:json_parser) do
        if defined?(Yajl::Parser)
          Yajl::Parser
        elsif defined?(JSON)
          JSON
        else
          raise "You must require yajl or json gem"
        end
      end

      let(:xml_parser) { SimpleXMLParser }

      let(:parser) do
        case format
        when :json
          json_parser
        when :xml
          xml_parser
        end
      end

      let(:expected_mime_type) { Mime::Types.lookup_by_extension(format).to_s }
      let(:expected_encoding) { 'utf-8' }
    end
  end

  module Macros
    module Rack
      def request(method, _url, payload = nil, &blk)
        describe "#{method.to_s.upcase} #{_url}" do
          rack_request(method, _url, &payload)
          instance_eval(&blk)
        end
      end

      def rack_request(method, _url, format = :json, &_payload) 
        raise "Unimplemented format #{format}" unless format == :json
        _payload_mime_type = Mime::Type.lookup_by_extension(format).to_s
        _payload = lambda { nil } unless _payload

        let(:request) do
          req_opts = { :method => method }.merge(request_headers)
          req_opts[:input] = request_payload.send("to_#{format}") unless request_payload.nil?
          r = ::Rack::MockRequest.env_for(request_url_prefix + request_url, req_opts)
          r.merge!({ 'CONTENT_TYPE' => _payload_mime_type }) unless request_payload.nil?
          r # I dare you to delete this line
        end
        let(:request_url) { _url } 
        let(:request_payload, &_payload) 
      end

      def expects_status(response_status)
        it "should respond with status #{response_status} #{SpecHelpers::HTTP::STATUS_CODES[response_status.to_s]}" do
          status.should eql(response_status)
        end
      end

      def expects_content_type(mime_type, charset = nil)
        it "should respond with content type of #{mime_type}" do
          content_type.should match(%r{^#{mime_type}})
        end

        if charset
          it "should respond encoded in #{charset}" do
            content_type.should match(%r{charset=#{charset}})
          end
        end
      end
    end
  end
end

RSpec::Core::ExampleGroup.send(:extend, SpecHelpers::Macros::Rack)
