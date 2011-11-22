module Intermodal
  module RSpec
    module Resources
      extend ActiveSupport::Concern

      included do
        include Intermodal::RSpec::Rack
        include Intermodal::RSpec::AuthenticatedRequests
        include Intermodal::RSpec::PaginatedCollection

        let(:resource_collection_name) { resource_name.pluralize }
        let(:model) { resource_name.camelize.constantize }
        let(:parent_models) { parent_names.map { |p| p.to_s.singularize.camelize.constantize } }

        let(:model_collection) do
          3.times { model.make!(model_factory_options) }
          (model_parent ? model.by_parent(model_parent) : model.all )
        end

        let(:model_resource) { model.make!(model_factory_options) }
        let(:model_factory_options) { (model_parent ? { parent_names.last.to_s.singularize => model_parent } : {} ) }
        let(:model_parents) { parent_models.map { |p| p.make! } }
        let(:model_parent) { model_parents.last }
        let(:presenter) { api.presenter_for model }

        let(:collection) { model_collection }
        let(:paginated_collection) { model_collection.paginate(:page => page, :per_page => per_page) }
        let(:presented_collection) { parser.decode(paginated_collection.send("to_#{format}", :presenter => presenter, :root => collection_element_name)) }
        let(:page) { 1 }
        let(:per_page) { WillPaginate.per_page }

        let(:resource_element_name) { model.name.demodulize.underscore }
        let(:collection_element_name) { resource_element_name.pluralize }
        let(:expected_resource) { model.find(model_resource.id) }
        let(:persisted_resource_id) { body[resource_name]['id'] }
        let(:fetch_resource) { model.find(persisted_resource_id) }
        let(:resource_after_update) { model.find(resource_id) }
        let(:resource_after_destroy) { resource_after_update }
        let(:resource) { parser.decode(expected_resource.send("to_#{format}", :root => resource_element_name, :presenter => presenter))}
        let(:resource_id) { resource[resource_name]['id'] }
        let(:parent_ids) { parent_names.zip(model_parents.map { |m| m.id }) }

        let(:namespace) { nil }
        let(:namespace_path) { ( namespace ? "/#{namespace}" : nil ) }
        let(:parent_path) { parent_ids.map { |p, p_id| "/#{p}/#{p_id}" }.join }
        let(:collection_url) { [ namespace_path, parent_path, "/#{resource_collection_name}.#{format}" ].join }
        let(:resource_url) { [ namespace_path, parent_path, "/#{resource_collection_name}/#{resource_id}.#{format}" ].join }

        let(:request_json_payload) { { resource_element_name => request_payload }.to_json }
        let(:request_xml_payload) { request_payload.to_xml(:root => resource_element_name) }

        let(:malformed_json_payload) { '{ "bad": [ "data": ] }' }
        let(:malformed_xml_payload) { '<bad><data></bad></data>' }

        # DELETE specs expect record to be deleted.
        # Override this if you are using something such as ActiveResource:
        # let(:record_not_found_error) { ActiveResource::ResourceNotFound }
        let(:record_not_found_error) { ActiveRecord::RecordNotFound }

        # Some of the test examples assume that the database is blank.
        # For example, index tests require injecting 3 resources and expects
        # the index endpoint to return exactly 3 resources.
        let(:reset_datastore!) { } # Do nothing by default
      end

      module ClassMethods
        def given_create_attributes(values = {})
          let(:valid_create_attributes) { values }
        end

        def given_update_attributes(values = {})
          let(:valid_update_attributes) { values }
        end

        def metadata_for_resources(resource_name, options = {})
          if resource_name.is_a?(Array)
            parents = resource_name
            resource_name = parents.pop
          end
          resource_name = resource_name.to_s if resource_name.is_a?(Symbol)

          { :formats => [ :json, :xml ],
            :resource_name => resource_name,
            :model_name => resource_name.singularize,
            :encoding => 'utf-8',
            :parents => parents || [],
            :namespace_path => ( options[:namespace] ? "/#{options[:namespace]}" : nil )
          }.merge(options)
        end

        def metadata_for_formatted_resource(format, options = {})
          { :format => format,
            :collection_url => collection_url_for_resource(options[:namespace_path], options[:parents], options[:resource_name], format),
            :resource_url => resource_url_for_resource(options[:namespace_path], options[:parents], options[:resource_name], format),
            :mime_type => Mime::Type.lookup_by_extension(format).to_s
          }.merge(options)
        end

        def parent_path_for_resource(parents)
          parents.map { |p| "/#{p}/:id" }.join
        end

        def collection_url_for_resource(namespace, parents, resource_name, format)
          [ namespace, parent_path_for_resource(parents), "/#{resource_name}.#{format}" ].join
        end

        def resource_url_for_resource(namespace, parents, resource_name, format)
          [ namespace, parent_path_for_resource(parents), "/#{resource_name}/:id.#{format}" ].join
        end

        def resources(resource_name, options = {}, &blk)
          options = metadata_for_resources(resource_name, options)
          _resource_name = options[:resource_name].singularize

          options[:formats].each do |format|
            format_options = metadata_for_formatted_resource(format, options)
            context format_options[:collection_url], format_options do
              let(:namespace) { options[:namespace] }
              let(:resource_name) { _resource_name }
              let(:parent_names) { options[:parents] }
              let(:format) { format }
              let(options[:parents].last) { model_parent } if options[:parents].last
              instance_eval(&blk) if blk
            end
          end
        end

        def expects_resource_crud(options = {}, &blk)
          expected_actions = options[:only] || [ :index, :show, :create, :update, :destroy ]
          expected_actions -= options[:except] if options[:except]

          expected_actions.each do |action|
            send("expects_#{action}")
          end
        end

        STANDARD_SUCCESSFUL_STATUS_FOR = {
          :index => 200,
          :show => 200,
          :create => 201,
          :update => 200,
          :destroy => 200 }

        STANDARD_REQUEST_FOR = {
          :index => { :method => :get, :end_point => :collection_url },
          :show => { :method => :get, :end_point => :resource_url },
          :create => { :method => :post, :end_point => :collection_url, :payload => proc do valid_create_attributes end },
          :update => { :method => :put, :end_point => :resource_url, :payload => proc do valid_update_attributes end },
          :destroy => { :method => :delete, :end_point => :resource_url } }

        def request_resource_action(action, options = {}, &blk)
          options = {
            :mime_type => metadata[:mime_type],
            :encoding => metadata[:encoding],
            :status => STANDARD_SUCCESSFUL_STATUS_FOR[action],
            :collection_url => metadata[:collection_url],
            :resource_url => metadata[:resource_url]
          }.merge(STANDARD_REQUEST_FOR[action]).merge(options)

          request options[:method], options[options[:end_point]], options[:payload] do
            let(:request_url) { send(options[:end_point]) }
            expects_status(options[:status])
            expects_content_type(options[:mime_type], options[:encoding])
            instance_eval(&blk) if blk
          end
        end

        def expects_index(options = {}, &additional_examples)
          request_resource_action(:index, options) do
            it "should return a list of all #{metadata[:resource_name]}" do
              reset_datastore!
              collection.should_not be_empty
              body.should eql(presented_collection)
            end

            expects_unauthorized_access_to_respond_with_401
            unless options[:skip_pagination_examples]
              expects_pagination do
                before(:each) { reset_datastore! }
              end
            end
            instance_eval(&additional_examples) if additional_examples
          end
        end

        def expects_show(options = {}, &additional_examples)
          request_resource_action(:show, options) do
            it "should return a #{metadata[:resource_name]} of id 1" do
              resource.should_not be_nil
              body.should eql(resource)
            end

            with_non_existent_resource_should_respond_with_404
            expects_unauthorized_access_to_respond_with_401
            instance_eval(&additional_examples) if additional_examples
          end
        end

        def expects_create(options = {}, &additional_examples)
          request_resource_action(:create, options) do
            it "should return the newly created #{metadata[:resource_name]}" do
              body.should eql(parser.decode(fetch_resource.send("to_#{format}", { :presenter => presenter, :root => resource_element_name})))
            end

            with_malformed_data_should_respond_with_400
            expects_unauthorized_access_to_respond_with_401
            instance_eval(&additional_examples) if additional_examples
          end
        end

        def expects_update(options = {}, &additional_examples)
          request_resource_action(:update, options) do
            it "should update #{metadata[:resource_name]}" do
              response.should_not be(nil)
              valid_update_attributes.each do |updated_attribute, updated_value|
                resource_after_update[updated_attribute].should eql(updated_value)
              end
            end

            with_malformed_data_should_respond_with_400
            with_non_existent_resource_should_respond_with_404
            expects_unauthorized_access_to_respond_with_401
            instance_eval(&additional_examples) if additional_examples
          end
        end

        def expects_destroy(options = {}, &additional_examples)
          request_resource_action(:destroy, options) do
            it "should delete #{metadata[:resource_name]}" do
              response.should_not be(nil)
              lambda { resource_after_destroy }.should raise_error(record_not_found_error)
            end

            with_non_existent_resource_should_respond_with_404
            expects_unauthorized_access_to_respond_with_401
            instance_eval(&additional_examples) if additional_examples
          end
        end

        def with_malformed_data_should_respond_with_400
          context "with malformed #{metadata[:format]} payload" do
            let(:request_raw_payload) { send("malformed_#{format}_payload") }

            expects_status(400)
            expects_content_type(metadata[:mime_type], metadata[:encoding])
          end
        end

        def with_non_existent_resource_should_respond_with_404
          context 'with non-existent resource' do
            let(:resource_id) { 0 } # Assumes that persisted datastore never uses id of 0
            expects_status 404
          end
        end

        def expects_json_presentation(_presenter_scope = nil)
          let(:presenter_scope) { _presenter_scope } if _presenter_scope

          it 'should present a JSON object' do
            body.should eql(presented_resource)
          end
        end
      end
    end
  end
end
