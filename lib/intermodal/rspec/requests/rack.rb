module Intermodal
  module RSpec
    module Rack
      extend ActiveSupport::Concern

      class SimpleXMLParser
        def self.decode(*args)
          Hash.from_xml(*args)
        end
      end

      included do
        subject { response }

        # Define the Rack Application you are testing
        let(:application) { fail NotImplementedError, 'Must define let(:application)' }
        let(:http_headers) { Hash.new }
        # let(:request_headers) { rack_compliant_headers(http_headers) }
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
        let(:body) { parser.decode(raw_body) }

        let(:json_parser) { MultiJson }
        let(:xml_parser) { SimpleXMLParser }

        let(:parser) do
          case format
          when :json
            json_parser
          when :xml
            xml_parser
          end
        end

        # Override to change payload Content-Type
        let(:request_payload_mime_type) { Mime::Type.lookup_by_extension(format).to_s }

        # Override to change JSON payload builder
        let(:request_json_payload) { request_payload.to_json }

        # Override to change XML payload builder
        let(:request_xml_payload) { request_payload.to_xml }

        # Override to send arbitrary payloads
        let(:request_raw_payload) { send("request_#{format}_payload") unless request_payload.nil? }

        let(:expected_mime_type) { Mime::Types.lookup_by_extension(format).to_s }
        let(:expected_encoding) { 'utf-8' }

        # Broken out so you can use this outside of let()
        def rack_compliant_headers(_headers = {})
          _headers.to_a.inject({}) do |m,kv|
            m.tap do |_m|
              _h, _v = kv
              _m["HTTP_#{_h}".underscore.upcase] = _v
            end
          end
        end

        def rack_compliant_request(_method, _url, _headers, _body, format = :json)
          _payload_mime_type = (format.is_a?(Symbol) ? Mime::Type.lookup_by_extension(format) : format)
          req_opts = { :method => _method }.merge(rack_compliant_headers(_headers))
          req_opts[:input] = _body
          ::Rack::MockRequest.env_for(_url, req_opts).tap do |_r|
            _r.merge!({ 'CONTENT_TYPE' => _payload_mime_type.to_s }) unless _body.nil?
          end
        end
      end

      module ClassMethods
        def request(method, _url, payload = nil, &blk)
          describe "#{method.to_s.upcase} #{_url}" do
            rack_request(method, _url, &payload)
            instance_eval(&blk)
          end
        end

        def rack_request(method, _url, _format = nil, &_payload)
          _format = _format # Scope for closure
          _payload = proc do nil end unless _payload

          let(:format) { _format } if _format
          let(:request) { rack_compliant_request(method,
                                                 request_url_prefix + request_url,
                                                 http_headers,
                                                 request_raw_payload,
                                                 (request_raw_payload ? request_payload_mime_type : nil) ) }
          let(:request_url) { _url }
          let(:request_payload, &_payload)
        end

        def expects_status(response_status)
          it "should respond with status #{response_status} #{Intermodal::RSpec::HTTP::STATUS_CODES[response_status.to_s]}" do
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

        def expects_empty_body
          it "should respond with a Rack-compliant empty body" do
            response[2].should be_empty
            response[2].should be_respond_to(:each)
          end
        end
      end
    end
  end
end
