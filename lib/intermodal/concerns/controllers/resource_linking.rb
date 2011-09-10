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
        let(:presentation_root) { collection_name }
        let(:presentation_scope) { nil } # Will default to :default scope
      end

      def index
        (respond_with model.get(:all, :parent_id => params[:id]).to_target_ids).tap(&WATCH)
      end

      def create
        (respond_with model.replace(params[:id], target_ids, :account => account), :location => nil).tap(&WATCH)
      end

      def update
        (respond_with(model.append(params[:id], target_ids, :account => account))).tap(&WATCH)
      end

      def destroy
        (respond_with(model.remove(params[:id], target_ids, :account => account))).tap(&WATCH)
      end
    end
  end
end
