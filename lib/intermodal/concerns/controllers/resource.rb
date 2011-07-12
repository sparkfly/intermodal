module Intermodal
  module Controllers
    module Resource
      extend ActiveSupport::Concern

      included do
        include Intermodal::Controllers::Accountability
        include Intermodal::Controllers::Anonymous

        respond_to :xml, :json
        self.responder = ResourceResponder

        class_inheritable_accessor :model, :resource, :api

        let(:model) { self.class.model || self.class.resource.to_s.classify.constantize }
        let(:resource) { self.class.resource.to_s }
        let(:resource_name) { resource.singularize }
        let(:model_name) { model.name.underscore.to_sym }

        let(:api) { self.class.api }
        let(:acceptor) { api.acceptors[model_name] }
        let(:accepted_params) { acceptor.call(params[resource_name] || {}) }
      end

      # Actions
      def index
        respond_with(collection)
      end

      def show
        respond_with(object)
      end

      def create
        respond_with(model.create(create_params))
      end

      def update
        object.update_attributes(update_params)
        respond_with(object)
      end

      def destroy
        object.destroy
        respond_with(object)
      end
    end
  end
end
