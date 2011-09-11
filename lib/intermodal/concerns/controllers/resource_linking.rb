module Intermodal
  module Controllers
    module ResourceLinking
      extend ActiveSupport::Concern

      included do
        class_inheritable_accessor :api

        include Intermodal::Controllers::Accountability
        include Intermodal::Controllers::Anonymous

        respond_to :json, :xml
        self.responder = ResourceResponder

        let(:collection_name) { self.class.collection_name.to_s } # TODO: This might already be defined in Rails 3.x
        let(:collection) { model.get(:all, :parent_id => params[:id]).to_target_ids }

        # :target_element_name: Params key for list of linked resource ids
        let(:target_element_name) { "#{target_resource_name.to_s.singularize}_ids" }

        # :accepted_params: All attribute and values for resource
        let(:accepted_params) { params[parent_resource_name] || {} }

        # :target_ids: List of ids extracted from params
        let(:target_ids) { accepted_params[target_element_name] }

        let(:presentation_root) { parent_resource_name }
        let(:presentation_scope) { nil } # Will default to :default scope
        let(:presented_collection) do
          Intermodal::Proxies::LinkingResources.new presentation_root,
            :to => target_resource_name,
            :with => collection
        end
      end

      def index
        respond_with presented_collection
      end

      def create
        respond_with model.replace(params[:id], target_ids, :account => account), :location => nil
      end

      def update
        respond_with(model.append(params[:id], target_ids, :account => account))
      end

      def destroy
        respond_with(model.remove(params[:id], target_ids, :account => account))
      end
    end
  end
end
