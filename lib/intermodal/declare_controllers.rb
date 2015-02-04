module Intermodal
  module DeclareControllers
    extend ActiveSupport::Concern

    included do
      attr_accessor :controller_definitions

      def self.controllers(&blk)
        self.instance.controllers(&blk)
      end

      def self.load_controllers!
        self.instance.load_controllers!
      end
    end

    def controllers(&blk)
      self.controller_definitions = blk
    end

    def resources(name, options = {}, &blk)
      controller_name = _controller_name(name)
      _create_controller(name, controller_name, blk, :model => options[:model], :ancestor => Intermodal::ResourceController, :api => self)
    end

    def nested_resources(parent_name, name, options = {}, &blk)
      _parent_model = options[:parent_model]
      _parent_resource_name = parent_name.to_s.singularize.to_sym
      _namespace = _module(parent_name)
      controller_name = _controller_name(name)

      _create_controller(name, controller_name, blk,
                         :ancestor => Intermodal::NestedResourceController,
                         :namespace => _namespace,
                         :model => options[:model],
                         :parent_resource_name => _parent_resource_name,
                         :parent_model => _parent_model,
                         :api => self)
    end

    def link_resources_from(parent_name, options = {}, &blk)
      _model = options[:model]
      _parent_model = options[:parent_model]
      _parent_resource_name = parent_name.to_s.singularize.to_sym
      _target_resource_name = options[:to]
      _namespace = _module(parent_name)
      controller_name = _controller_name(_target_resource_name)

      collection_name = "#{_target_resource_name.to_s.singularize}_ids"

      customize_linking_resource = proc do
        let(:model) { _model }
        let(:parent_resource_name) { _parent_resource_name }
        let(:target_resource_name) { _target_resource_name }
      end

      controller = _create_controller(collection_name, controller_name, customize_linking_resource,
                                      :ancestor => Intermodal::LinkingResourceController,
                                      :namespace => _namespace,
                                      :model => _model,
                                      :parent_resource => _parent_resource_name,
                                      :parent_model => _parent_model,
                                      :api => self)
      controller.instance_eval(&blk) if blk
    end

    def load_controllers!
      self.controller_definitions.call
    end

    # API: private
    def _create_controller(collection_name, controller_name, customizations, options = {},  &blk)
      _ancestor = options[:ancestor] || ApplicationController
      _namespace = options[:namespace] #|| Object

      _unload_controller_if_exists(controller_name, _namespace)

      _namespace ||= Object

      controller = Class.new(_ancestor)
      _namespace.const_set(controller_name, controller)

      controller.collection_name = collection_name
      controller.model = options[:model] if options[:model]
      controller.parent_resource_name = options[:parent_resource_name] if options[:parent_resource_name]
      controller.parent_model = parent_model if options[:parent_model]
      controller.class_eval(&customizations) if customizations
      controller.api = options[:api] if options[:api]

      controller
    end

    def _controller_name(name)
      case name
      when String then name.to_s
      when Symbol then "#{name.to_s.camelize}Controller"
      else
        raise "resources require String or Symbol"
      end
    end

    def _module(module_name)
      module_name = module_name.to_s.camelize
      if Object.const_defined?(module_name)
        module_name.constantize
      else
        Object.const_set(module_name, Module.new)
      end
    end

    def _unload_controller_if_exists(controller_name, _namespace = nil)
      full_controller_name = [_namespace, controller_name].join('::')

      # I found no other good way to detect this without using eval that would work
      # for both 1.8.7 and 1.9.2
      (_namespace || Object).send(:remove_const, controller_name) if eval "defined? #{full_controller_name}" # Unload existing class
    end
  end
end
