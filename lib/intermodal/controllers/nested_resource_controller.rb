module Intermodal
  class NestedResourceController < Intermodal::APIController
    include Intermodal::Controllers::Resource

    private
    class_inheritable_accessor :parent_resource_name, :parent_model

    let(:parent_model) { self.class.parent_model || self.class.parent_resource_name.to_s.classify.constantize }
    let(:collection) { model.get(:all, :account => account, :parent_id => parent_id) }
    let(:resource) { model.get(params[:id], :account => account, :parent_id => parent_id) }
    let(:parent_resource) { parent_model.get(parent_id, :account => account) }

    let(:parent_id_name) { "#{parent_resource_name}_id".to_sym }
    let(:parent_id) { params[parent_id_name] }
    let(:create_params) { accepted_params.merge( parent_id_name => parent_resource.id ) }
    let(:update_params) { accepted_params }
  end
end
