module Intermodal
  module Controllers
    module Resource
      extend ActiveSupport::Concern

      included do
        include Intermodal::Controllers::Accountability
        include Intermodal::Controllers::Anonymous

        respond_to :json, :xml

        class_inheritable_accessor :model, :collection_name, :api

        let(:collection) { raise 'You must define collection' }
        let(:resource) { raise 'You must define resource' }
        let(:presented_collection) { collection.paginate :page => params[:page] }

        let(:model) { self.class.model || self.class.collection_name.to_s.classify.constantize }
        let(:collection_name) { self.class.collection_name.to_s } # TODO: This might already be defined in Rails 3.x
        let(:resource_name) {collection_name.singularize }
        let(:model_name) { model.name.underscore.to_sym }
        
        # Wrap JSON with root key?
        let(:presentation_root) { resource_name }
        let(:presentation_scope) { nil } # Will default to :default scope
      end

      # Actions
      def index
        respond_with presented_collection, :presentation_root => collection_name
      end

      def show
        respond_with resource
      end

      def create
        respond_with model.create(create_params)
      end

      def update
        resource.update_attributes(update_params)
        respond_with resource
      end

      def destroy
        resource.destroy
        respond_with resource
      end
    end
  end
end
