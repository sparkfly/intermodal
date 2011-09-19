module Intermodal
  class LinkingResourceController < Intermodal::APIController
    include Intermodal::Controllers::ResourceLinking
    class_inheritable_accessor :model, :collection_name, :parent_resource_name, :parent_model, :target_resource_name

    self.responder = Intermodal::LinkingResourceResponder
  end
end
