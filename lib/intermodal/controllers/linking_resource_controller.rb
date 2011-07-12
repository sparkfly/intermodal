module Intermodal
  class LinkingResourceController < ApplicationController
    include Intermodal::Controllers::ResourceLinking
    class_inheritable_accessor :model, :resource, :parent_resource, :parent_model, :target_resource
  end
end

