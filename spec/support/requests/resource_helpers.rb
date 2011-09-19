require 'yajl'

module SpecHelpers
  module Resources
    extend ActiveSupport::Concern

    included do
      include SpecHelpers::Rack

      let(:resource_collection_name) { resource_name.pluralize }
      let(:model) { resource_name.camelize.constantize }
      let(:parent_models) { parent_names.map { |p| p.to_s.singularize.camelize.constantize } }

      let(:model_collection) do
        3.times { model.make(model_factory_options) }
        (model_parent ? model.by_parent(model_parent) : model.all )
      end
      let(:model_resource) { model.make(model_factory_options) }
      let(:model_factory_options) { (model_parent ? { parent_names.last.to_s.singularize => model_parent } : {} ) }
      let(:model_parents) { parent_models.map { |p| p.make } }
      let(:model_parent) { model_parents.last }

      let(:collection) { parser.parse(model_collection.to_a.send("to_#{format}")) }
      let(:resource) { parser.parse(model.find(model_resource.id).send("to_#{format}")) }
      let(:resource_id) { resource[resource_name]['id'] }
      let(:parent_ids) { parent_names.zip(model_parents.map { |m| m.id }) }

      let(:namespace) { nil }
      let(:namespace_path) { ( namespace ? "/#{namespace}" : nil ) }
      let(:parent_path) { parent_ids.map { |p, p_id| "/#{p}/#{p_id}" }.join }
      let(:collection_url) { [ namespace_path, parent_path, "/#{resource_collection_name}.#{format}" ].join }
      let(:resource_url) { [ namespace_path, parent_path, "/#{resource_collection_name}/#{resource_id}.#{format}" ].join } 
    end
  end

  module Macros
    module Resources
      def given_attributes(kind, values)
        # Rebind to scope
        model_name = metadata[:model_name].to_sym
        let("valid_#{kind}_attributes".to_sym) { { model_name => values } }
      end

      def given_create_attributes(values = {})
        given_attributes(:create, values)
      end

      def given_update_attributes(values = {})
        given_attributes(:update, values)
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
        resource_name = options[:resource_name]

        options[:formats].each do |format|
          format_options = metadata_for_formatted_resource(format, options)
          context format_options[:collection_url], format_options do
            let(:namespace) { options[:namespace] }
            let(:resource_name) { resource_name.singularize }
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
        :create => { :method => :post, :end_point => :collection_url, :payload => lambda { valid_create_attributes } }, 
        :update => { :method => :put, :end_point => :resource_url, :payload => lambda { valid_update_attributes } }, 
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
            collection.should_not be_empty
            body.should eql(collection)
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

          instance_eval(&additional_examples) if additional_examples
        end
      end

      def expects_create(options = {}, &additional_examples)
        request_resource_action(:create, options) do
          it "should return the newly created #{metadata[:resource_name]}" do
            body.should eql(parser.parse(model.find(body[resource_name]['id']).send("to_#{format}")))
          end

          instance_eval(&additional_examples) if additional_examples
        end
      end

      def expects_update(options = {}, &additional_examples)
        request_resource_action(:update, options) do
          it "should update #{metadata[:resource_name]}" do
            response.should_not be(nil)
            updated_resource = model.find(resource_id)
            valid_update_attributes[resource_name.to_sym].each do |updated_attribute, updated_value|
              updated_resource[updated_attribute].should eql(updated_value)
            end
          end

          instance_eval(&additional_examples) if additional_examples
        end
      end

      def expects_destroy(options = {}, &additional_examples)
        request_resource_action(:destroy, options) do
          it "should delete #{metadata[:resource_name]}" do
            response.should_not be(nil)
            lambda { model.find(resource_id) }.should raise_error(ActiveRecord::RecordNotFound)
          end

          instance_eval(&additional_examples) if additional_examples
        end
      end

    end
  end
end

RSpec::Core::ExampleGroup.send(:extend, SpecHelpers::Macros::Resources)
